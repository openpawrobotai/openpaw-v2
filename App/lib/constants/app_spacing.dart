import 'package:flutter/material.dart';
import 'app_colors.dart';

/// PawPilot spacing / radius / shadow scale.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16; // standard padding
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14; // standard card/control radius
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadow, offset: Offset(0, 6), blurRadius: 14),
  ];
  static const List<BoxShadow> raised = [
    BoxShadow(color: AppColors.shadowStrong, offset: Offset(0, 12), blurRadius: 24),
  ];
}
