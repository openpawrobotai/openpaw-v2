import 'package:flutter/material.dart';

/// PawPilot design-system palette (warm coral on cream). Existing key names are
/// kept (primary, background, textPrimary, …) so screens restyle automatically;
/// PawPilot-specific tokens (primaryTint, surfaceMuted, info…) are added.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFF47B5A);      // coral
  static const Color primaryDark = Color(0xFFE56A48);  // pressed
  static const Color primaryLight = Color(0xFFFFE7DD); // tint (badges)
  static const Color primarySoft = Color(0xFFFFF1EA);  // card/surface tint

  // Backgrounds & surfaces
  static const Color background = Color(0xFFFAF6F2);    // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5EFE9);

  // Text
  static const Color textPrimary = Color(0xFF16110D);
  static const Color textSecondary = Color(0xFF6E665F);
  static const Color textTertiary = Color(0xFFA39B94);
  static const Color textHint = Color(0xFFA39B94);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & dividers
  static const Color divider = Color(0xFFEDE5DD);
  static const Color border = Color(0xFFEDE5DD);
  static const Color borderStrong = Color(0xFFDCD2C7);

  // Semantic
  static const Color success = Color(0xFF0FA678);
  static const Color successSoft = Color(0xFFDCFAEC);
  static const Color warning = Color(0xFFE59A14);
  static const Color warningSoft = Color(0xFFFFF3D8);
  static const Color error = Color(0xFFE2553D);
  static const Color errorSoft = Color(0xFFFFE0D8);
  static const Color info = Color(0xFF3F8CFF);
  static const Color infoSoft = Color(0xFFE2EEFF);

  // Utility
  static const Color shadow = Color(0x14140F0F);       // rgba(20,17,15,0.08)
  static const Color shadowStrong = Color(0x2E140F0F); // rgba(20,17,15,0.18)
}
