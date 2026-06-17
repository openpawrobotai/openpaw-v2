import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import 'robot_detail_page.dart';
import 'add_robot_instruction_screen.dart';
import 'health_showcase_screen.dart'; // ✅ NEW IMPORT

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final Color _accentBlue = AppColors.primary;
  static final Color _textSecondary = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ================= HEADER =================
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                          NetworkImage(widget.user.photoURL ?? ''),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${widget.user.displayName?.split(" ").first ?? 'User'}!',
                              style: theme.textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Welcome back to PawMe',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {},
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await AuthService().signOut();
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WelcomeScreen(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.cardColor,
                              foregroundColor:
                              theme.textTheme.bodyLarge?.color,
                              elevation: 0,
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Logout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ================= ROBOTS =================
              Text(
                'Your Robots',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
                children: [
                  _buildRobotCard('Rex Unit 01', '85%', '92%', true),
                  _buildRobotCard(
                    'Rover Scout',
                    '15%',
                    '0%',
                    false,
                    status: 'CHARGING',
                  ),
                  _buildAddRobotCard(),
                  _buildHealthShowcaseCard(), // ✅ NEW CARD
                ],
              ),

              const SizedBox(height: 30),

              // ================= DAILY ROUTINES =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Routines',
                    style: theme.textTheme.headlineMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Manage All',
                      style: TextStyle(color: _accentBlue),
                    ),
                  ),
                ],
              ),

              _buildRoutineItem(
                Icons.medication_outlined,
                Colors.redAccent,
                'Morning Medicine',
                '08:00 AM',
                true,
              ),
              _buildRoutineItem(
                Icons.restaurant_outlined,
                Colors.orangeAccent,
                'Breakfast Kibble',
                '08:30 AM',
                true,
              ),
              _buildRoutineItem(
                Icons.directions_walk_outlined,
                Colors.greenAccent,
                'Park Walk',
                '05:00 PM',
                false,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ROBOT CARD =================
  Widget _buildRobotCard(
      String name,
      String battery,
      String signal,
      bool isOnline, {
        String status = 'ONLINE',
      }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: theme.brightness == Brightness.light
            ? Border.all(
          color: AppColors.divider.withOpacity(0.6),
          width: 1,
        )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.show_chart, color: _accentBlue),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: isOnline
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 6),
              Text(status, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Battery', battery, Icons.battery_charging_full),
              _buildMetric('Signal', signal, Icons.wifi),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RobotDetailPage(
                      name: name,
                      battery: battery,
                      signal: signal,
                      status: status,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnline ? _accentBlue : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Details'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEALTH SHOWCASE CARD =================
  Widget _buildHealthShowcaseCard() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HealthShowcaseScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: theme.brightness == Brightness.light
              ? Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.2,
          )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite,
                size: 36, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Health Showcase',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Why your dog’s health matters',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: theme.iconTheme.color),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }

  Widget _buildAddRobotCard() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddRobotInstructionScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32),
            SizedBox(height: 8),
            Text('Connect New Robot'),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(
      IconData icon,
      Color iconBg,
      String title,
      String time,
      bool isDone,
      ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: theme.brightness == Brightness.light
            ? Border.all(
          color: AppColors.divider.withOpacity(0.6),
          width: 1,
        )
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconBg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(time, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            isDone
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: isDone ? _accentBlue : theme.iconTheme.color,
          ),
        ],
      ),
    );
  }
}
