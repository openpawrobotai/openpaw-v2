import 'dart:convert';
import 'package:http/http.dart' as http;

/// Current firmware on the robot, from GET /ota/info.
class FirmwareInfo {
  final String version;
  final String partition;
  final bool canRollback;

  FirmwareInfo({
    required this.version,
    required this.partition,
    required this.canRollback,
  });

  factory FirmwareInfo.fromJson(Map<String, dynamic> j) => FirmwareInfo(
        version: (j['version'] ?? 'unknown').toString(),
        partition: (j['partition'] ?? '').toString(),
        canRollback: j['can_rollback'] == true,
      );
}

/// Live update progress, from GET /ota/status.
class OtaProgress {
  final String state; // idle | checking | downloading | up_to_date | success | error
  final int percent;
  final String message;

  OtaProgress({required this.state, required this.percent, required this.message});

  factory OtaProgress.fromJson(Map<String, dynamic> j) => OtaProgress(
        state: (j['state'] ?? 'idle').toString(),
        percent: (j['percent'] ?? 0) is int
            ? j['percent']
            : int.tryParse('${j['percent']}') ?? 0,
        message: (j['message'] ?? '').toString(),
      );

  bool get isBusy => state == 'checking' || state == 'downloading';
}

/// Talks to the robot's OTA endpoints and to the public GitHub manifest (the
/// same source the robot pulls from, so the app can show "what's available").
class FirmwareService {
  final String host; // robot LAN IP
  FirmwareService(this.host);

  String get _base => 'http://$host';

  // Stable public URL that always resolves to the newest release's assets.
  static const String manifestUrl =
      'https://github.com/openpawrobotai/openpaw-v2/releases/latest/download/manifest.json';
  static const String board = 'esp32_ball_v1';

  Future<FirmwareInfo> info() async {
    final r = await http
        .get(Uri.parse('$_base/ota/info'))
        .timeout(const Duration(seconds: 4));
    return FirmwareInfo.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<OtaProgress> status() async {
    final r = await http
        .get(Uri.parse('$_base/ota/status'))
        .timeout(const Duration(seconds: 4));
    return OtaProgress.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<void> startUpdate() async {
    await http
        .get(Uri.parse('$_base/ota/update'))
        .timeout(const Duration(seconds: 5));
  }

  /// Returns true if the robot accepted the rollback (and is rebooting).
  Future<bool> rollback() async {
    final r = await http
        .get(Uri.parse('$_base/ota/rollback'))
        .timeout(const Duration(seconds: 6));
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return j['ok'] == true;
  }

  /// Latest published version for this board, or null if there's no release yet
  /// / it couldn't be reached.
  Future<String?> latestVersion() async {
    try {
      final r = await http
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final boards = j['boards'] as Map<String, dynamic>?;
      final entry = boards?[board] as Map<String, dynamic>?;
      return entry?['version']?.toString();
    } catch (_) {
      return null;
    }
  }
}
