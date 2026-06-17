import 'dart:async';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../services/firmware_service.dart';

/// Firmware update + rollback for one robot. Shows the running version vs. the
/// latest published build, drives the on-device OTA, and survives the reboot
/// by polling until the robot comes back.
class FirmwareUpdatePage extends StatefulWidget {
  final String host; // robot LAN IP
  const FirmwareUpdatePage({super.key, required this.host});

  @override
  State<FirmwareUpdatePage> createState() => _FirmwareUpdatePageState();
}

enum _Phase { loading, idle, updating, rebooting, error }

class _FirmwareUpdatePageState extends State<FirmwareUpdatePage> {
  late final FirmwareService _fw = FirmwareService(widget.host);

  _Phase _phase = _Phase.loading;
  FirmwareInfo? _info;
  String? _latest; // latest published version, or null if none/unreachable
  bool _checkedLatest = false;
  String _progressMsg = '';
  int _progressPct = 0;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool get _updateAvailable =>
      _latest != null && _info != null && _latest != _info!.version;

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final info = await _fw.info();
      if (!mounted) return;
      setState(() {
        _info = info;
        _phase = _Phase.idle;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't reach the robot. Make sure it's powered on and on Wi-Fi.";
        _phase = _Phase.error;
      });
      return;
    }
    // Check the published manifest separately — failure here is non-fatal.
    final latest = await _fw.latestVersion();
    if (!mounted) return;
    setState(() {
      _latest = latest;
      _checkedLatest = true;
    });
  }

  Future<void> _startUpdate() async {
    setState(() {
      _phase = _Phase.updating;
      _progressMsg = 'Starting…';
      _progressPct = 0;
      _error = null;
    });
    try {
      await _fw.startUpdate();
    } catch (_) {
      // The robot may already be applying; fall through to polling.
    }
    _pollStatus();
  }

  void _pollStatus() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      try {
        final s = await _fw.status();
        if (!mounted) return;
        setState(() {
          _progressMsg = s.message;
          _progressPct = s.percent;
        });
        if (s.state == 'success') {
          // Image written; the robot reboots now.
          _poll?.cancel();
          _waitForReboot();
        } else if (s.state == 'up_to_date') {
          _poll?.cancel();
          await _load();
          _toast('Already on the latest firmware.');
        } else if (s.state == 'error') {
          _poll?.cancel();
          if (mounted) {
            setState(() {
              _phase = _Phase.error;
              _error = s.message.isEmpty ? 'Update failed.' : s.message;
            });
          }
        }
      } catch (_) {
        // Lost contact mid-download usually means it's rebooting into the
        // new image — switch to waiting for it to return.
        if (_progressPct > 0 || _progressMsg.toLowerCase().contains('install')) {
          _poll?.cancel();
          _waitForReboot();
        }
      }
    });
  }

  /// Poll /ota/info until the robot answers again (post-reboot), then refresh.
  void _waitForReboot() {
    setState(() {
      _phase = _Phase.rebooting;
      _progressMsg = 'Restarting robot…';
    });
    final previous = _info?.version;
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final info = await _fw.info();
        if (!mounted) return;
        _poll?.cancel();
        final latest = await _fw.latestVersion();
        if (!mounted) return;
        setState(() {
          _info = info;
          _latest = latest;
          _checkedLatest = true;
          _phase = _Phase.idle;
        });
        _toast(info.version != previous
            ? 'Updated to ${info.version} ✓'
            : 'Robot is back online.');
      } catch (_) {
        // still rebooting — keep waiting
      }
    });
  }

  Future<void> _rollback() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Roll back firmware?'),
        content: const Text(
            'The robot will restart on the previously installed firmware.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Roll back')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final accepted = await _fw.rollback();
      if (!accepted) {
        _toast('Nothing to roll back to.');
        return;
      }
    } catch (_) {
      // rollback reboots immediately, so the response often never arrives
    }
    _waitForReboot();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmware')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.error:
        return _centerMessage(Icons.error_outline, _error ?? 'Something went wrong',
            action: ('Try again', _load));
      case _Phase.updating:
      case _Phase.rebooting:
        return _buildProgress();
      case _Phase.idle:
        return _buildIdle();
    }
  }

  Widget _buildIdle() {
    final info = _info!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _versionCard(info),
        const SizedBox(height: AppSpacing.md),
        if (!_checkedLatest)
          const SizedBox.shrink()
        else if (_latest == null)
          _infoBanner(Icons.cloud_off, AppColors.textSecondary,
              "Couldn't check for updates. You're still running ${info.version}.")
        else if (_updateAvailable)
          _infoBanner(Icons.system_update, AppColors.primary,
              'Update available: $_latest')
        else
          _infoBanner(Icons.verified, AppColors.success,
              "You're on the latest firmware."),
        const SizedBox(height: AppSpacing.lg),
        if (_updateAvailable)
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _startUpdate,
              icon: const Icon(Icons.download),
              label: Text('Update to $_latest'),
            ),
          ),
        if (info.canRollback) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _rollback,
              icon: const Icon(Icons.history),
              label: const Text('Roll back to previous'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Check again'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Updates download over the robot's Wi-Fi and install to a spare slot. "
          "If a new build fails to start, the robot automatically reverts to the "
          "current one — it won't get bricked.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _versionCard(FirmwareInfo info) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.memory, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Installed firmware', style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(info.version, style: theme.textTheme.titleMedium),
                Text('Slot: ${info.partition}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final rebooting = _phase == _Phase.rebooting;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (rebooting)
            const CircularProgressIndicator()
          else
            Column(
              children: [
                LinearProgressIndicator(
                  value: _progressPct > 0 ? _progressPct / 100 : null,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('$_progressPct%',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _progressMsg.isEmpty ? 'Working…' : _progressMsg,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Keep the robot powered and nearby. This can take a minute.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _infoBanner(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _centerMessage(IconData icon, String text,
      {(String, VoidCallback)? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(onPressed: action.$2, child: Text(action.$1)),
            ],
          ],
        ),
      ),
    );
  }
}
