import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_iot/wifi_iot.dart';
import '../constants/app_colors.dart';
import 'robot_reboot_page.dart';

class HomeWifiSetupPage extends StatefulWidget {
  const HomeWifiSetupPage({super.key});

  @override
  State<HomeWifiSetupPage> createState() => _HomeWifiSetupPageState();
}

class _HomeWifiSetupPageState extends State<HomeWifiSetupPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isSending = false;

  Future<void> _provisionRobot() async {
    if (_ssidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your Home WiFi SSID")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Force WiFi usage so the request doesn't leak out over mobile data
      await WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint("Sending credentials to http://192.168.4.1/wifi...");

      final response = await http.post(
        Uri.parse('http://192.168.4.1/wifi'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'ssid': _ssidController.text.trim(),
          'pass': _passController.text.trim(), // FIXED: Changed 'password' to 'pass' to match your firmware
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint("Robot Response: ${response.statusCode} - ${response.body}");

    } catch (e) {
      // Note: A 'Timeout' or 'Connection closed' catch is common here
      // because the robot reboots immediately after receiving the packet.
      debugPrint("Request finished with expected interruption: $e");
    } finally {
      // 2. Give the robot a moment to process before releasing WiFi lock
      await Future.delayed(const Duration(seconds: 1));
      await WiFiForIoTPlugin.forceWifiUsage(false);

      if (mounted) {
        setState(() => _isSending = false);
        // Move to the reboot countdown page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RobotRebootPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Step 2: Provision Robot"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text("Configuration", style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            const Text(
              "Enter the SSID and Password of your Home WiFi. The robot will reboot and attempt to join this network.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: "Home WiFi SSID",
                hintText: "e.g. MyHomeNetwork",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "WiFi Password",
                hintText: "••••••••",
              ),
            ),
            const Spacer(),
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _provisionRobot,
                  child: _isSending
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text("Connect Robot to Home WiFi"),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}