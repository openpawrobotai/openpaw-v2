import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'robot_control_page.dart';

class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Remote Control',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              children: const [
                Icon(Icons.sports_esports,
                    color: Colors.white, size: 48),
                SizedBox(height: 12),
                Text(
                  'Select a Robot to Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose from your available robots',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= ROBOT LIST =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _RobotControlCard(
                  name: 'Rex Unit 01',
                  battery: '85%',
                  signal: '92%',
                  isOnline: true,
                ),
                SizedBox(height: 16),
                _RobotControlCard(
                  name: 'Rover Scout',
                  battery: '15%',
                  signal: '0%',
                  isOnline: false,
                  status: 'CHARGING',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotControlCard extends StatelessWidget {
  final String name;
  final String battery;
  final String signal;
  final bool isOnline;
  final String status;

  const _RobotControlCard({
    required this.name,
    required this.battery,
    required this.signal,
    required this.isOnline,
    this.status = 'ONLINE',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),

        // ✅ visible in light mode
        border: theme.brightness == Brightness.light
            ? Border.all(
          color: AppColors.divider.withOpacity(0.6),
        )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: isOnline ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color:
                        isOnline ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ================= METRICS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric(context, Icons.battery_charging_full,
                  'Battery', battery),
              _metric(context, Icons.wifi, 'Signal', signal),
            ],
          ),

          const SizedBox(height: 20),

          // ================= CONTROL BUTTON =================
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isOnline
                  ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const RobotControlPage(),
                                    ),
                                  );
              }
                  : null,
              icon: const Icon(Icons.sports_esports),
              label: const Text('Control Robot'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isOnline ? AppColors.primary : Colors.grey.shade400,
                foregroundColor:
                isOnline ? Colors.white : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.iconTheme.color),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
