import 'package:flutter/material.dart';

/// Hagez brand tokens — mirrored from the dashboard/API design system.
/// Keep in sync with packages/dashboard's inline style constants.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0F2044);
  static const teal = Color(0xFF1B8A7A);
  static const ctaBlue = Color(0xFF0057FF);

  // Category accents (mirrors dashboard sidebar / booking category chips)
  static const restaurant = Color(0xFFD2691E); // burnt orange
  static const salon = Color(0xFFE91E63); // magenta
  static const court = Color(0xFF2E7D32); // green
  static const gaming = Color(0xFF6B21A8); // purple
  static const carWash = Color(0xFF00ACC1); // cyan

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F8FA);
  static const border = Color(0xFFE5E7EB);
  static const textSecondary = Color(0xFF6B7280);
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFF59E0B);
  static const successBg = Color(0xFFE8F5F3);

  static Color forCategory(String category) {
    switch (category) {
      case 'restaurant':
        return restaurant;
      case 'salon':
        return salon;
      case 'court':
        return court;
      case 'gaming_cafe':
        return gaming;
      case 'car_wash':
        return carWash;
      default:
        return navy;
    }
  }
}

class AppTheme {
  AppTheme._();

  /// Arabic is the default locale, so Cairo is the base font family. Latin
  /// text (booking refs, EGP numerals in LTR contexts) should wrap with
  /// TextStyle(fontFamily: 'Inter') explicitly where needed.
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.navy,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Cairo',
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.navy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
