import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import '../constants/app_colors.dart';
import 'robot_control_page.dart'; // We will create this next

class HomeNetworkConnectPage extends StatefulWidget {
  const HomeNetworkConnectPage({super.key});

  @override
  State<HomeNetworkConnectPage> createState() => _HomeNetworkConnectPageState();
}

class _HomeNetworkConnectPageState extends State<HomeNetworkConnectPage> with WidgetsBindingObserver {
  bool _isConnected = false;
  String? _currentSSID;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Listen for when user returns to app
    _checkCurrentConnection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This triggers automatically when the user comes back from WiFi Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCurrentConnection();
    }
  }

  Future<void> _checkCurrentConnection() async {
    bool connected = await WiFiForIoTPlugin.isConnected();
    String? ssid = await WiFiForIoTPlugin.getSSID();

    setState(() {
      // Logic: If we have an SSID and it's not the setup hotspot, we're good
      _isConnected = connected && ssid != null && ssid != "<unknown ssid>" && ssid != "PAWME-SETUP";
      _currentSSID = ssid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Step 3: Connect Phone")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              _isConnected ? Icons.wifi_tethering : Icons.wifi_tethering_off,
              size: 80,
              color: _isConnected ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              _isConnected ? "Phone Connected!" : "Connect to Home WiFi",
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              _isConnected
                  ? "You are now on $_currentSSID. You can now control your robot."
                  : "Please go to settings and connect to the same WiFi you gave the robot.",
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (!_isConnected)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => WiFiForIoTPlugin.setEnabled(true, shouldOpenSettings: true),
                  child: const Text("Open WiFi Settings"),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isConnected
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RobotControlPage()))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? AppColors.primary : Colors.grey,
                ),
                child: const Text("Control Robot"),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}