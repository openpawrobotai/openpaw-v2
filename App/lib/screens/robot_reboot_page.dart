import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'home_network_connect_page.dart';

class RobotRebootPage extends StatefulWidget {
  const RobotRebootPage({super.key});

  @override
  State<RobotRebootPage> createState() => _RobotRebootPageState();
}

class _RobotRebootPageState extends State<RobotRebootPage> {
  int _secondsRemaining = 20;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        _navigateToFinalStep();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _navigateToFinalStep() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeNetworkConnectPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 6),
            const SizedBox(height: 40),
            Text("Robot Rebooting...", style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(
              "Please wait $_secondsRemaining seconds while the robot\nconnects to your home network.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}