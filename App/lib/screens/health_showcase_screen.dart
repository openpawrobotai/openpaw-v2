import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dog_health_analysis_screen.dart';

class HealthShowcaseScreen extends StatelessWidget {
  const HealthShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Health Showcase'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dog line graphic
            Image.asset(
              'assets/images/dog_line.png',
              height: 160,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 24),

            Text(
              'Why Your Dog’s Health Matters',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'A healthy dog lives longer, stays happier, and builds a stronger bond with you. '
                  'Monitoring activity, rest, and daily routines helps detect issues early and ensures '
                  'your pet gets the care it deserves.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            _infoCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Early Health Detection',
              description:
              'Track unusual behavior patterns and catch potential health issues before they become serious.',
            ),

            _infoCard(
              icon: Icons.directions_run,
              title: 'Balanced Activity',
              description:
              'Ensure your dog gets the right balance of exercise and rest every day.',
            ),

            _infoCard(
              icon: Icons.favorite,
              title: 'Better Quality of Life',
              description:
              'Consistent monitoring leads to a happier, safer, and healthier companion.',
            ),

            const SizedBox(height: 24),

            // ✅ BUTTON — lifted above system navigation safely
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DogHealthAnalysisScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Check Your Dog’s Health',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor, // ✅ FIX
            borderRadius: BorderRadius.circular(16),
            boxShadow: theme.brightness == Brightness.light
                ? const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ]
                : null, // ✅ no shadow in dark mode
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ), // ✅ FIX
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium, // ✅ FIX
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
