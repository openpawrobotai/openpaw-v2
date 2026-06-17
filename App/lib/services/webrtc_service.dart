import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Remote (over-internet) link to the robot via WebRTC.
///
/// The app is the **answerer**: the robot publishes an offer + its camera/MJPEG
/// track + a `control` DataChannel; we answer, render the video, and send
/// control over the channel. Signaling rides Firebase Realtime DB per
/// webrtc/SIGNALING.md (rooms at webrtc/{deviceId}).
class WebrtcService {
  WebrtcService(this.deviceId);

  /// Robot id, lowercase hex MAC without colons (e.g. "b8f862f87174").
  final String deviceId;

  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  RTCDataChannel? _control;
  DatabaseReference? _room;
  final List<StreamSubscription<dynamic>> _subs = [];

  final _statusCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _stateCtrl = StreamController<RTCPeerConnectionState>.broadcast();

  /// Periodic robot telemetry ({distance, temp_ambient, temp_object, laser, drive, turn}).
  Stream<Map<String, dynamic>> get status => _statusCtrl.stream;

  /// Peer-connection state, for "connecting / connected / failed" UI.
  Stream<RTCPeerConnectionState> get connectionState => _stateCtrl.stream;

  static const Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // TODO(turn): add a TURN server (Cloudflare/Metered) — required for
      // reliable NAT traversal when phone and robot are on different networks.
      // {'urls': 'turn:HOST:3478', 'username': 'USER', 'credential': 'PASS'},
    ],
  };

  Future<void> connect() async {
    await remoteRenderer.initialize();

    // RTDB rules require an authenticated owner; anonymous is fine for dev.
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final uid = auth.currentUser!.uid;

    final root = FirebaseDatabase.instance;
    _room = root.ref('webrtc/$deviceId');
    await root.ref('devices/$deviceId/owner').set(uid); // claim ownership

    _pc = await createPeerConnection(_config);

    _pc!.onTrack = (RTCTrackEvent e) {
      if (e.streams.isNotEmpty) {
        remoteRenderer.srcObject = e.streams.first;
      }
    };

    // The robot (offerer) opens the control channel; we receive it here.
    _pc!.onDataChannel = (RTCDataChannel ch) {
      _control = ch;
      ch.onMessage = _onControlMessage;
    };

    _pc!.onIceCandidate = (RTCIceCandidate c) {
      if (c.candidate == null) return;
      _room!.child('appCandidates').push().set({
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex,
      });
    };

    _pc!.onConnectionState = (RTCPeerConnectionState s) => _stateCtrl.add(s);

    // Start a fresh session and clear any stale offer/answer/candidates.
    await _room!.update({
      'session': DateTime.now().millisecondsSinceEpoch.toString(),
      'offer': null,
      'answer': null,
      'robotCandidates': null,
      'appCandidates': null,
    });

    // When the robot posts its offer, answer it.
    _subs.add(_room!.child('offer').onValue.listen((event) async {
      final value = event.snapshot.value;
      if (value == null || _pc == null) return;
      if (await _pc!.getRemoteDescription() != null) return; // already answered
      final m = Map<String, dynamic>.from(value as Map);
      await _pc!.setRemoteDescription(RTCSessionDescription(m['sdp'], m['type']));
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      await _room!.child('answer').set({'type': answer.type, 'sdp': answer.sdp});
    }));

    // Add the robot's ICE candidates as they arrive.
    _subs.add(_room!.child('robotCandidates').onChildAdded.listen((event) {
      final m = Map<String, dynamic>.from(event.snapshot.value as Map);
      _pc!.addCandidate(RTCIceCandidate(
        m['candidate'], m['sdpMid'], (m['sdpMLineIndex'] as num?)?.toInt()));
    }));
  }

  void _onControlMessage(RTCDataChannelMessage msg) {
    try {
      final m = jsonDecode(msg.text);
      if (m is Map && m['status'] is Map) {
        _statusCtrl.add(Map<String, dynamic>.from(m['status']));
      }
    } catch (_) {/* ignore non-JSON */}
  }

  Future<void> _send(Map<String, dynamic> m) async {
    if (_control?.state == RTCDataChannelState.RTCDataChannelOpen) {
      await _control!.send(RTCDataChannelMessage(jsonEncode(m)));
    }
  }

  Future<void> setMotor(int drive, int turn) =>
      _send({'cmd': 'motor', 'drive': drive, 'turn': turn});
  Future<void> toggleLaser() => _send({'cmd': 'laser'});
  Future<void> beep() => _send({'cmd': 'beep'});

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _control?.close();
    await _pc?.close();
    await remoteRenderer.dispose();
    await _statusCtrl.close();
    await _stateCtrl.close();
  }
}
