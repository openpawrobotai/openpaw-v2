import 'package:shared_preferences/shared_preferences.dart';

/// A robot the app has already provisioned. Persisted so we don't force the
/// Wi-Fi setup screen on every launch — the robot keeps its Wi-Fi creds in NVS
/// and auto-reconnects, so we just need to remember how to reach it.
class RobotProfile {
  final String host; // last known LAN IP (or 192.168.4.1 in AP mode)
  final String? deviceId; // robot MAC w/o colons → WebRTC signaling room id
  final String name;

  const RobotProfile({
    required this.host,
    this.deviceId,
    this.name = 'PAWME Robot',
  });
}

class RobotStore {
  RobotStore._();

  static const _kHost = 'robot_host';
  static const _kId = 'robot_id';
  static const _kName = 'robot_name';

  /// Remember (or update) the robot. Call this whenever we learn the robot's
  /// current LAN IP — e.g. right after provisioning succeeds.
  static Future<void> save(RobotProfile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kHost, p.host);
    await sp.setString(_kName, p.name);
    if (p.deviceId != null && p.deviceId!.isNotEmpty) {
      await sp.setString(_kId, p.deviceId!);
    }
  }

  /// The remembered robot, or null if none has been provisioned yet.
  static Future<RobotProfile?> load() async {
    final sp = await SharedPreferences.getInstance();
    final host = sp.getString(_kHost);
    if (host == null || host.isEmpty) return null;
    return RobotProfile(
      host: host,
      deviceId: sp.getString(_kId),
      name: sp.getString(_kName) ?? 'PAWME Robot',
    );
  }

  /// Forget the robot — next launch starts from Wi-Fi setup again.
  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kHost);
    await sp.remove(_kId);
    await sp.remove(_kName);
  }
}
