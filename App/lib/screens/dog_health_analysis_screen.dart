import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DogHealthAnalysisScreen extends StatefulWidget {
  const DogHealthAnalysisScreen({super.key});

  @override
  State<DogHealthAnalysisScreen> createState() =>
      _DogHealthAnalysisScreenState();
}

class _DogHealthAnalysisScreenState
    extends State<DogHealthAnalysisScreen> {
  late final double topFactor;
  late final double leftFactor;

  @override
  void initState() {
    super.initState();

    // Random position (kept subtle)
    final rand = Random();
    topFactor = 0.25 + rand.nextDouble() * 0.35;
    leftFactor = 0.2 + rand.nextDouble() * 0.45;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dog Health Status'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            Text(
              'Possible itching detected',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Highlighted areas indicate where your dog may be experiencing discomfort.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Dog + overlay
            AspectRatio(
              aspectRatio: 1.6,
              child: Stack(
                children: [
                  // Dog line
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/dog_line.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Red gradient overlay (small & subtle)
                  Positioned(
                    top: topFactor * MediaQuery.of(context).size.width * 0.6,
                    left:
                    leftFactor * MediaQuery.of(context).size.width * 0.6,
                    child: Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: RadialGradient(
                          colors: [
                            Colors.red.withOpacity(0.55),
                            Colors.red.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: theme.brightness == Brightness.light
                    ? Border.all(
                  color: AppColors.divider.withOpacity(0.6),
                )
                    : null,
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is an early indication. Consult a veterinarian if the behavior persists.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
