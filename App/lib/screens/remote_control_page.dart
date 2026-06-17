import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/webrtc_service.dart';

/// Over-the-internet control: live WebRTC video + DataChannel control.
/// Use this when away from the robot (vs RobotControlPage for the LAN).
class RemoteControlPage extends StatefulWidget {
  const RemoteControlPage({super.key, required this.deviceId});

  /// Robot id (lowercase hex MAC, no colons), e.g. from BLE INFO.
  final String deviceId;

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage> {
  late final WebrtcService _rtc;
  RTCPeerConnectionState _state = RTCPeerConnectionState.RTCPeerConnectionStateNew;
  Map<String, dynamic> _status = const {};
  StreamSubscription<dynamic>? _stateSub, _statusSub;
  String? _error;

  static const int _speed = 200; // -255..255

  @override
  void initState() {
    super.initState();
    _rtc = WebrtcService(widget.deviceId);
    _stateSub = _rtc.connectionState.listen((s) => mounted ? setState(() => _state = s) : null);
    _statusSub = _rtc.status.listen((s) => mounted ? setState(() => _status = s) : null);
    _rtc.connect().catchError((e) {
      if (mounted) setState(() => _error = '$e');
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _statusSub?.cancel();
    _rtc.dispose();
    super.dispose();
  }

  bool get _connected =>
      _state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  String get _stateLabel {
    switch (_state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return 'Connected';
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return 'Connection failed';
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return 'Disconnected';
      default:
        return 'Connecting…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_connected ? 'PawMe (remote)' : _stateLabel,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _error != null
                      ? Center(child: Text('Error: $_error',
                          style: const TextStyle(color: Colors.white70)))
                      : RTCVideoView(_rtc.remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
                ),
                if (!_connected && _error == null)
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
                Positioned(
                  bottom: 8, left: 8, right: 8,
                  child: _statusBar(),
                ),
              ],
            ),
          ),
          _controls(),
        ],
      ),
    );
  }

  Widget _statusBar() {
    final d = _status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('${d['distance'] ?? 0}mm', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('${(d['temp_object'] ?? 0).toString()}°', style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('laser ${(d['laser'] == true) ? 'on' : 'off'}',
              style: TextStyle(color: d['laser'] == true ? Colors.redAccent : Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _controls() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dpadButton(Icons.keyboard_arrow_up, _speed, 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dpadButton(Icons.keyboard_arrow_left, 0, -_speed),
              const SizedBox(width: 12),
              _ActionBtn(icon: Icons.stop, label: 'STOP', color: Colors.redAccent,
                  onTap: () => _rtc.setMotor(0, 0)),
              const SizedBox(width: 12),
              _dpadButton(Icons.keyboard_arrow_right, 0, _speed),
            ],
          ),
          _dpadButton(Icons.keyboard_arrow_down, -_speed, 0),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionBtn(icon: Icons.flare, label: 'LASER', onTap: _rtc.toggleLaser),
              const SizedBox(width: 16),
              _ActionBtn(icon: Icons.volume_up, label: 'BEEP', onTap: _rtc.beep),
            ],
          ),
        ],
      ),
    );
  }

  /// Press-and-hold to move, release to stop (safety).
  Widget _dpadButton(IconData icon, int drive, int turn) {
    return GestureDetector(
      onTapDown: (_) => _rtc.setMotor(drive, turn),
      onTapUp: (_) => _rtc.setMotor(0, 0),
      onTapCancel: () => _rtc.setMotor(0, 0),
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }
}
