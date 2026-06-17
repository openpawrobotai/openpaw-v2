import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_colors.dart';
import '../services/ble_provisioning_service.dart';
import 'robot_control_page.dart';
import 'remote_control_page.dart';

/// BLE-based Wi-Fi provisioning: scan for the robot, connect, send Home Wi-Fi
/// credentials over GATT, and watch the connection status it reports back.
class BleWifiSetupPage extends StatefulWidget {
  const BleWifiSetupPage({super.key});

  @override
  State<BleWifiSetupPage> createState() => _BleWifiSetupPageState();
}

enum _Phase { scanning, connecting, form }

class _BleWifiSetupPageState extends State<BleWifiSetupPage> {
  final BleProvisioningService _ble = BleProvisioningService();
  final TextEditingController _ssid = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  _Phase _phase = _Phase.scanning;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<({int status, int reason})>? _statusSub;
  StreamSubscription<List<String>>? _netSub;
  List<ScanResult> _found = [];
  List<String> _wifiNetworks = []; // SSIDs the robot scanned
  String _info = '';
  int? _wifiStatus; // 0 idle 1 connecting 2 connected 3 failed
  int _wifiReason = 0; // firmware Wi-Fi disconnect reason (when failed)
  String? _error;
  bool _sending = false;
  bool _sent = false; // have we pushed creds this session? (gates the status banner)
  bool _obscurePass = true; // password show/hide toggle
  String? _robotIp;   // LAN IP reported by the robot once it's on Wi-Fi
  String? _deviceId;  // robot MAC (no colons) → WebRTC signaling room id

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _phase = _Phase.scanning;
      _found = [];
      _error = null;
    });

    // Android 12+ needs runtime BLUETOOTH_SCAN/CONNECT (+ location on older).
    // iOS surfaces its own Bluetooth prompt when the scan starts — don't gate here
    // (the Android permission objects report "denied" on iOS and would false-fail).
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      if (statuses.values.any((s) => s.isPermanentlyDenied)) {
        setState(() => _error =
            'Bluetooth & location permission is blocked. Enable it in Settings to find your robot.');
        return;
      }
    }

    // Wait for the BLE adapter to power on. On iOS this also triggers the
    // system Bluetooth permission prompt on first launch.
    try {
      await FlutterBluePlus.adapterState
          .firstWhere((s) => s == BluetoothAdapterState.on)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Turn on Bluetooth, then tap Rescan.');
      }
      return;
    }

    _scanSub?.cancel();
    _scanSub = _ble.scanForRobots().listen((results) {
      if (mounted) setState(() => _found = results);
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _phase = _Phase.connecting;
      _error = null;
      _sent = false;       // fresh session — don't show last attempt's status
      _wifiStatus = null;
    });
    try {
      await _ble.connect(device);
      final info = await _ble.readInfo();
      _netSub = _ble.scanNetworks().listen((list) {
        if (mounted) setState(() => _wifiNetworks = list);
      });
      _statusSub = _ble.statusStream().listen((s) async {
        if (!mounted) return;
        setState(() {
          _wifiStatus = s.status;
          _wifiReason = s.reason;
        });
        if (s.status == 2) {
          // Connected: pull the robot's LAN IP from INFO ("version|mac|ip").
          try {
            final parts = (await _ble.readInfo()).split('|');
            if (mounted) {
              setState(() {
                if (parts.length >= 3 && parts[2].isNotEmpty) _robotIp = parts[2];
                if (parts.length >= 2 && parts[1].isNotEmpty) {
                  _deviceId = parts[1].replaceAll(':', '').toLowerCase();
                }
              });
            }
          } catch (_) {}
        }
      });
      if (!mounted) return;
      setState(() {
        _info = info;
        _phase = _Phase.form;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not connect: $e';
        _phase = _Phase.scanning;
      });
      _startScan();
    }
  }

  Future<void> _send() async {
    if (_ssid.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick or enter your Wi-Fi network first')));
      return;
    }
    if (_pass.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter the Wi-Fi password')));
      return;
    }
    setState(() {
      _sending = true;
      _sent = true; // now the status banner is meaningful
    });
    try {
      await _ble.provision(_ssid.text.trim(), _pass.text);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to send credentials: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _statusSub?.cancel();
    _netSub?.cancel();
    _ble.stopScan();
    _ble.disconnect();
    _ssid.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Connect Robot to Wi-Fi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null && _phase == _Phase.scanning && _found.isEmpty) {
      return _centered(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _startScan, child: const Text('Retry')),
        ],
      ));
    }
    switch (_phase) {
      case _Phase.scanning:
        return _buildScanList(theme);
      case _Phase.connecting:
        return _centered(const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to robot…'),
          ],
        ));
      case _Phase.form:
        return _buildForm(theme);
    }
  }

  Widget _buildScanList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Find your robot', style: theme.textTheme.displaySmall),
        const SizedBox(height: 8),
        const Text(
          'Make sure your robot is powered on. Nearby OpenPaw robots appear below.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _found.isEmpty
              ? _centered(const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Scanning…'),
                  ],
                ))
              : ListView.separated(
                  itemCount: _found.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _found[i];
                    final name = r.device.platformName.isNotEmpty
                        ? r.device.platformName
                        : r.advertisementData.advName;
                    return ListTile(
                      leading: const Icon(Icons.pets, color: AppColors.primary),
                      title: Text(name),
                      subtitle: Text('Signal ${r.rssi} dBm'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _connect(r.device),
                    );
                  },
                ),
        ),
        SafeArea(
          child: TextButton(onPressed: _startScan, child: const Text('Rescan')),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuration', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            _info.isEmpty
                ? 'Connected. Pick your Home Wi-Fi (2.4 GHz) — the robot will join it.'
                : 'Connected to firmware ${_info.split('|').first}. Pick your Home Wi-Fi (2.4 GHz).',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _ssidField(theme),
          const SizedBox(height: 16),
          TextField(
            controller: _pass,
            obscureText: _obscurePass,
            enableInteractiveSelection: true, // allow long-press paste
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Wi-Fi Password',
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                tooltip: _obscurePass ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_sent && _wifiStatus != null) ...[_statusBanner(theme), const SizedBox(height: 12)],
          if (_robotIp != null) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => RobotControlPage(initialIp: _robotIp))),
                icon: const Icon(Icons.videocam),
                label: const Text('Open camera & controls (local)'),
              ),
            ),
            if (_deviceId != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RemoteControlPage(deviceId: _deviceId!))),
                  icon: const Icon(Icons.cloud),
                  label: const Text('Watch remotely (WebRTC)'),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Send to Robot'),
            ),
          ),
        ],
      ),
    );
  }

  /// SSID input: a text field while the robot is still scanning, then a
  /// dropdown of the networks it found.
  Widget _ssidField(ThemeData theme) {
    if (_wifiNetworks.isEmpty) {
      return TextField(
        controller: _ssid,
        decoration: const InputDecoration(
          labelText: 'Home Wi-Fi SSID',
          hintText: 'Scanning for networks…',
          suffixIcon: Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    }
    final selected = _wifiNetworks.contains(_ssid.text) ? _ssid.text : null;
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Home Wi-Fi (2.4 GHz)'),
      hint: const Text('Select a network'),
      items: _wifiNetworks
          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (v) => setState(() => _ssid.text = v ?? ''),
    );
  }

  // Map the firmware's Wi-Fi disconnect reason to an actionable message.
  String _failMessage(int reason) {
    const wrongPassword = {2, 3, 15, 202, 204, 205}; // auth / 4-way handshake failures
    const notFound = {200, 201}; // beacon timeout / no AP found
    if (wrongPassword.contains(reason)) {
      return 'Wrong Wi-Fi password — re-enter it and try again.';
    }
    if (notFound.contains(reason)) {
      return "Couldn't find that network — make sure it's 2.4 GHz and in range.";
    }
    return "Couldn't connect (code $reason) — double-check the network and password.";
  }

  Widget _statusBanner(ThemeData theme) {
    final (label, color, icon) = switch (_wifiStatus) {
      1 => ('Robot is connecting to Wi-Fi…', AppColors.warning, Icons.wifi_find),
      2 => ('Robot connected to Wi-Fi!', AppColors.success, Icons.wifi),
      3 => (_failMessage(_wifiReason), AppColors.error, Icons.wifi_off),
      _ => ('Waiting for credentials…', AppColors.textSecondary, Icons.hourglass_empty),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => Center(child: child);
}
