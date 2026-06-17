import 'package:flutter/material.dart';

import '../services/robot_store.dart';
import 'ble_wifi_setup_page.dart';
import 'robot_control_page.dart';

/// Picks the launch screen: if a robot was already provisioned, go straight to
/// its live camera & controls; otherwise start the BLE Wi-Fi setup flow.
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  late final Future<RobotProfile?> _robot = RobotStore.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RobotProfile?>(
      future: _robot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final robot = snap.data;
        if (robot == null) return const BleWifiSetupPage();
        return RobotControlPage(initialIp: robot.host, deviceId: robot.deviceId);
      },
    );
  }
}
