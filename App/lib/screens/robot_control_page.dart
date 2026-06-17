import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_iot/wifi_iot.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';
import '../services/robot_store.dart';
import 'ble_wifi_setup_page.dart';

class RobotControlPage extends StatefulWidget {
  final String? initialIp;
  final String? deviceId; // robot MAC w/o colons → WebRTC signaling room id
  const RobotControlPage({super.key, this.initialIp, this.deviceId});

  @override
  State<RobotControlPage> createState() => _RobotControlPageState();
}

class _RobotControlPageState extends State<RobotControlPage> {
  String? _robotIp;
    bool _isSearching = true;

  /* Status */
  int _distance = 0;
  double _tempAmbient = 0.0;
  double _tempObject = 0.0;
  bool _laserOn = false;
  int _drive = 0;
  int _turn = 0;

  /* Recording */
  bool _isRecording = false;
  bool _showPreview = true;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;
  String? _localVideoPath;
  Session? _ffmpegSession;

  /* Status polling */
  Timer? _statusTimer;
  /* Motor heartbeat — re-sends the held direction so the robot's 2s safety
     timeout doesn't cut the motors when the joystick is held steady. */
  Timer? _motorTimer;

  /* Motor smoothing */
    double _driveVal = 0;
  double _turnVal = 0;

  @override
    void initState() {
      super.initState();
      if (widget.initialIp != null) {
        _robotIp = widget.initialIp;
        _isSearching = false;
        _startStatusPolling();
      } else {
        _checkWifiAndConnect();
      }
    }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _motorTimer?.cancel();
    _recordTimer?.cancel();
    _ffmpegSession?.cancel();
    super.dispose();
  }

  String get _baseUrl => 'http://$_robotIp';
  String get _streamUrl => 'http://$_robotIp:81/stream';

  /* ==================== ROBOT MANAGEMENT ==================== */

  /// Re-run BLE Wi-Fi setup (e.g. moved to a new network, or the IP changed).
  void _reprovision() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BleWifiSetupPage()),
    );
  }

  /// Forget the saved robot and return to setup.
  Future<void> _forgetRobot() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget this robot?'),
        content: const Text(
            "You'll need to set it up over Bluetooth again to reconnect."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Forget')),
        ],
      ),
    );
    if (ok != true) return;
    await RobotStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BleWifiSetupPage()),
    );
  }

  /* ==================== CONNECTION ==================== */

    Future<void> _checkWifiAndConnect() async {
      try {
        String? ssid = await WiFiForIoTPlugin.getSSID();
        debugPrint('PAWME: Current SSID = "$ssid"');
        /* Check if connected to PAWME-Robot (case-insensitive) */
        if (ssid != null && ssid.toLowerCase().contains('pawme')) {
          _robotIp = '192.168.4.1';
          _isSearching = false;
          _startStatusPolling();
          if (mounted) setState(() {});
          return;
        }
      } catch (e) {
        debugPrint('PAWME: WiFi check error: $e');
      }
      /* SSID didn't match — try direct connect anyway */
      _tryDirectConnect();
    }

    Future<void> _tryDirectConnect() async {
      const candidates = ['192.168.4.1', '192.168.1.1'];
      for (final ip in candidates) {
        try {
          final res = await http.get(Uri.parse('http://$ip/status'))
              .timeout(const Duration(seconds: 1));
          if (res.statusCode == 200) {
            _robotIp = ip;
            _isSearching = false;
            _startStatusPolling();
            if (mounted) setState(() {});
            return;
          }
        } catch (_) {}
      }
      /* Nothing found */
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }

  /* ==================== STATUS POLLING ==================== */

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _fetchStatus());
    _fetchStatus();
    // Re-send the current motor command while a direction is held (the joystick
    // only fires on movement, so without this the 2s safety timeout stops it).
    _motorTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_driveVal != 0 || _turnVal != 0) _sendMotor(_driveVal, _turnVal);
    });
  }

  Future<void> _fetchStatus() async {
    if (_robotIp == null) return;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/status'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _distance = data['distance'] ?? 0;
          _tempAmbient = (data['temp_ambient'] ?? 0.0).toDouble();
          _tempObject = (data['temp_object'] ?? 0.0).toDouble();
          _laserOn = data['laser'] ?? false;
          _drive = data['drive'] ?? 0;
          _turn = data['turn'] ?? 0;
        });
      }
    } catch (_) {}
  }

  /* ==================== MOTOR CONTROL ==================== */

  Future<void> _sendMotor(double drive, double turn) async {
    if (_robotIp == null) return;
    final d = (drive * 255).round().clamp(-255, 255);
    final t = (turn * 255).round().clamp(-255, 255);
    try {
      await http.get(Uri.parse('$_baseUrl/motor?drive=$d&turn=$t'))
          .timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  /* ==================== LASER & BEEP ==================== */

  Future<void> _toggleLaser() async {
    if (_robotIp == null) return;
    try {
      await http.get(Uri.parse('$_baseUrl/laser'))
          .timeout(const Duration(seconds: 2));
      _fetchStatus();
    } catch (_) {}
  }

  Future<void> _sendBeep() async {
    if (_robotIp == null) return;
    try {
      await http.get(Uri.parse('$_baseUrl/beep'))
          .timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  /* ==================== RECORDING ==================== */

  void _toggleRecording() {
    if (_robotIp == null) return;
    if (!_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _showPreview = false;
    });
    await Future.delayed(const Duration(milliseconds: 1500));

    final tempDir = await getTemporaryDirectory();
    _localVideoPath = '${tempDir.path}/pawme_${DateTime.now().millisecondsSinceEpoch}.mp4';
    _recordDuration = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });

    final command = '-f mjpeg -i $_streamUrl -c:v mpeg4 -q:v 5 -y $_localVideoPath';
    _ffmpegSession = await FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        await _moveToGallery();
      }
      setState(() => _showPreview = true);
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    if (_ffmpegSession != null) {
      await _ffmpegSession!.cancel();
      await Future.delayed(const Duration(seconds: 2));
    }
    setState(() => _isRecording = false);
  }

  Future<void> _moveToGallery() async {
    if (_localVideoPath == null) return;
    final file = File(_localVideoPath!);
    if (!await file.exists() || await file.length() == 0) return;
    final dir = Directory('/storage/emulated/0/DCIM/Pawme');
    if (!await dir.exists()) await dir.create(recursive: true);
    final newPath = '${dir.path}/pawme_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final newFile = await file.copy(newPath);
    await MediaScanner.loadMedia(path: newFile.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video saved to DCIM/Pawme")),
      );
    }
  }

  String _fmtDur(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  /* ==================== BUILD ==================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _robotIp != null ? 'PAWME Robot' : 'Connecting...',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_robotIp != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchStatus,
              tooltip: 'Refresh status',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'wifi') _reprovision();
              if (v == 'forget') _forgetRobot();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'wifi',
                child: ListTile(
                  leading: Icon(Icons.wifi),
                  title: Text('Set up Wi-Fi again'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'forget',
                child: ListTile(
                  leading: Icon(Icons.link_off),
                  title: Text('Forget this robot'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _robotIp == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching) ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    const Text('Searching for PAWME robot...',
                        style: TextStyle(color: Colors.white70)),
                  ] else ...[
                    const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
                    const SizedBox(height: 16),
                    const Text('No robot found',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() { _isSearching = true; _checkWifiAndConnect(); }),
                      child: const Text('Scan again'),
                    ),
                  ],
                ],
              ),
            )
          : _buildControlInterface(),
    );
  }

  Widget _buildControlInterface() {
    return Column(
      children: [
        /* ===== CAMERA STREAM ===== */
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Center(
                child: _showPreview
                    ? Mjpeg(
                        key: const ValueKey('preview'),
                        isLive: true,
                        stream: _streamUrl,
                      )
                    : const SizedBox.shrink(),
              ),
              if (_isRecording)
                Positioned(
                  top: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'REC ${_fmtDur(_recordDuration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              /* Status overlay */
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statusChip(Icons.straighten, '${_distance}mm'),
                      _statusChip(Icons.thermostat, '${_tempAmbient.toStringAsFixed(1)}°'),
                      _statusChip(Icons.whatshot, '${_tempObject.toStringAsFixed(1)}°'),
                      _statusChip(
                        Icons.toggle_on,
                        _laserOn ? 'ON' : 'OFF',
                        color: _laserOn ? Colors.redAccent : Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /* ===== CONTROLS ===== */
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: const Color(0xFF1A1A1A),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /* Joysticks row */
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Joystick(
                    label: 'DRIVE',
                    onChanged: (v) {
                      _driveVal = v;
                      _sendMotor(_driveVal, _turnVal);
                    },
                    axis: _JoystickAxis.vertical,
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          _ActionButton(
                            icon: Icons.stop_circle,
                            label: 'STOP',
                            color: Colors.redAccent,
                            onTap: () {
                              _driveVal = 0;
                              _turnVal = 0;
                              _sendMotor(0, 0);
                            },
                          ),
                          const SizedBox(width: 12),
                          _ActionButton(
                            icon: Icons.volume_up,
                            label: 'BEEP',
                            onTap: _sendBeep,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ActionButton(
                        icon: _laserOn ? Icons.toggle_on : Icons.toggle_off_outlined,
                        label: 'LASER',
                        color: _laserOn ? Colors.redAccent : null,
                        onTap: _toggleLaser,
                      ),
                    ],
                  ),
                  _Joystick(
                    label: 'TURN',
                    onChanged: (v) {
                      _turnVal = v;
                      _sendMotor(_driveVal, _turnVal);
                    },
                    axis: _JoystickAxis.horizontal,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              /* Record button */
              GestureDetector(
                onTap: _toggleRecording,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.red,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color ?? Colors.white, fontSize: 12)),
      ],
    );
  }
}

/* ==================== JOYSTICK WIDGET ==================== */

enum _JoystickAxis { vertical, horizontal }

class _Joystick extends StatefulWidget {
  final String label;
  final _JoystickAxis axis;
  final ValueChanged<double> onChanged;

  const _Joystick({
    required this.label,
    required this.onChanged,
    this.axis = _JoystickAxis.vertical,
  });

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  double _value = 0;
  double? _startPos;

  void _onStart(details) {
    _startPos = widget.axis == _JoystickAxis.vertical
        ? details.localPosition.dy
        : details.localPosition.dx;
  }

  void _onMove(details) {
    if (_startPos == null) return;
    final pos = widget.axis == _JoystickAxis.vertical
        ? details.localPosition.dy
        : details.localPosition.dx;
    final delta = pos - _startPos!;
    final range = 40.0;
    double v = -(delta / range);
    v = v.clamp(-1.0, 1.0);
    setState(() => _value = v);
    widget.onChanged(v);
  }

  void _onEnd(_) {
    setState(() => _value = 0);
    _startPos = null;
    widget.onChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    final knobOffset = widget.axis == _JoystickAxis.vertical
        ? Offset(0, -_value * 40)
        : Offset(_value * 40, 0);

    return GestureDetector(
      onPanStart: _onStart,
      onPanUpdate: _onMove,
      onPanEnd: _onEnd,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Stack(
          children: [
            Center(
              child: Transform.translate(
                offset: knobOffset,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE94560),
                    boxShadow: [
                      BoxShadow(color: Color(0x4DE94560), blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==================== ACTION BUTTON ==================== */

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: c, size: 22),
      ),
    );
  }
}