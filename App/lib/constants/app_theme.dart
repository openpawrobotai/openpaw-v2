import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// PawPilot-style theme: warm coral on cream, Inter for UI + Playfair Display
/// for editorial headings, soft rounded cards.
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color primaryText, Color secondaryText) {
    // Inter for everything, then Playfair Display for the big editorial styles.
    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: primaryText,
      displayColor: primaryText,
    );
    return base.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 36, fontWeight: FontWeight.w900, height: 1.15, color: primaryText),
      displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 30, fontWeight: FontWeight.w700, height: 1.2, color: primaryText),
      displaySmall: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: primaryText),
      headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700, color: primaryText),
      titleLarge: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w700, color: primaryText),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: primaryText),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: primaryText, height: 1.45),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: secondaryText, height: 1.45),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: secondaryText),
      labelLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  static InputDecorationTheme _inputTheme(Color fill, Color border) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: b(border),
      enabledBorder: b(border),
      focusedBorder: b(AppColors.primary, 2),
      errorBorder: b(AppColors.error),
      focusedErrorBorder: b(AppColors.error, 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    );
  }

  static ElevatedButtonThemeData get _elevatedButton => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  static OutlinedButtonThemeData get _outlinedButton => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.info,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.divider,
      elevatedButtonTheme: _elevatedButton,
      outlinedButtonTheme: _outlinedButton,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: _inputTheme(AppColors.surface, AppColors.border),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }

  // Warm dark variant (kept for ThemeProvider; light is the primary look).
  static ThemeData get darkTheme {
    const darkBg = Color(0xFF16110D);
    const darkSurface = Color(0xFF221C17);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.info,
        surface: darkSurface,
        onSurface: AppColors.background,
      ),
      textTheme: _textTheme(AppColors.background, AppColors.textTertiary),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.background),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.background),
      ),
      elevatedButtonTheme: _elevatedButton,
      outlinedButtonTheme: _outlinedButton,
      inputDecorationTheme: _inputTheme(darkSurface, const Color(0xFF3A322B)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
