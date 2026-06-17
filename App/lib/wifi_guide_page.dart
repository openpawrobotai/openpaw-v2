import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'constants/app_colors.dart';
// Removed home_page import as per your request
import 'screens/home_wifi_setup_page.dart';

class WifiGuidePage extends StatefulWidget {
  final String robotSSID;
  const WifiGuidePage({super.key, required this.robotSSID});

  @override
  State<WifiGuidePage> createState() => _WifiGuidePageState();
}

enum WifiStep { chooseNetwork, connecting, result }

class _WifiGuidePageState extends State<WifiGuidePage> {
  List<WifiNetwork> _wifiList = [];
  bool _isLoading = false;
  WifiStep _step = WifiStep.chooseNetwork;
  bool _connectionSuccess = false;
  bool _isConnectedToRobot = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;

    if (status.isGranted) {
      _startScan();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission and GPS must be ON')),
      );
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isLoading = true;
      _wifiList.clear();
      _step = WifiStep.chooseNetwork;
    });

    try {
      final results = await WiFiForIoTPlugin.loadWifiList();
      if (!mounted) return;

      setState(() {
        _wifiList = results
            .where((r) => r.ssid != null && r.ssid!.isNotEmpty)
            .toList()
          ..sort((a, b) => (b.level ?? -100).compareTo(a.level ?? -100));
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connectToWifi(WifiNetwork wifi, String password) async {
    setState(() {
      _step = WifiStep.connecting;
      _connectionSuccess = false;
      _isConnectedToRobot = false;
    });

    final isRobot = wifi.ssid == widget.robotSSID;

    try {
      await WiFiForIoTPlugin.forceWifiUsage(true);

      final success = await WiFiForIoTPlugin.connect(
        wifi.ssid!,
        password: isRobot ? null : password,
        joinOnce: true,
        security: isRobot ? NetworkSecurity.NONE : NetworkSecurity.WPA,
      ).timeout(const Duration(seconds: 12), onTimeout: () => false);

      if (!mounted) return;

      final currentSsid = await WiFiForIoTPlugin.getSSID();
      final actuallyConnectedToRobot = currentSsid == widget.robotSSID || currentSsid == '"${widget.robotSSID}"';

      setState(() {
        _connectionSuccess = success || actuallyConnectedToRobot;
        _isConnectedToRobot = isRobot && _connectionSuccess;
        _step = WifiStep.result;
      });

    } catch (_) {
      if (mounted) {
        setState(() {
          _connectionSuccess = false;
          _step = WifiStep.result;
        });
      }
    } finally {
      // Keep forcing wifi if it's the robot so the browser/http can talk to 192.168.4.1
      if (!isRobot) {
        await WiFiForIoTPlugin.forceWifiUsage(false);
      }
    }
  }

  Future<void> _askPassword(WifiNetwork wifi) async {
    if (wifi.ssid == widget.robotSSID) {
      _connectToWifi(wifi, "");
      return;
    }

    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter WiFi Password'),
        content: TextField(controller: controller, obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (password != null) {
      _connectToWifi(wifi, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(theme),
            const SizedBox(height: 30),
            Expanded(child: _buildContent(theme)),
            const SizedBox(height: 20),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    if (_step == WifiStep.connecting) {
      return Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text('Connecting...', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Joining the robot hotspot...', textAlign: TextAlign.center),
        ],
      );
    }

    return Column(
      children: [
        Text(
          _step == WifiStep.result
              ? (_connectionSuccess ? 'Connected!' : 'Connection Failed')
              : 'Connect to Robot',
          style: theme.textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _step == WifiStep.result
              ? (_connectionSuccess
              ? 'Successfully joined ${widget.robotSSID}.'
              : 'Could not establish connection.')
              : 'Select your Robot to begin setup.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading || _step == WifiStep.connecting) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: _wifiList.length,
      itemBuilder: (_, i) {
        final wifi = _wifiList[i];
        final isRobot = wifi.ssid == widget.robotSSID;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _askPassword(wifi),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRobot ? AppColors.primary : theme.dividerColor,
                  width: isRobot ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isRobot ? Icons.smart_toy : Icons.wifi,
                    color: isRobot ? AppColors.primary : theme.iconTheme.color,
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: Text(wifi.ssid!)),
                  if (isRobot)
                    const Text(
                      'SETUP',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              // If connected successfully
              if (_step == WifiStep.result && _connectionSuccess) {
                // Take user to the Setup Page (No Home Page logic here)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeWifiSetupPage()),
                );
              } else {
                // If failed or in default state, Refresh/Retry
                _startScan();
              }
            },
            child: Text(
              _step == WifiStep.result
                  ? (_connectionSuccess ? 'Connect to Home Network' : 'Retry')
                  : 'Refresh List',
            ),
          ),
        ),
      ),
    );
  }
}