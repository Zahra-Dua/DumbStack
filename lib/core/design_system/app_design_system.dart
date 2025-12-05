import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Modern Design System for SafeNest App
/// Provides consistent spacing, typography, and component styles
class AppDesignSystem {
  // Spacing System (8px grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 999.0;

  // Elevation/Shadows
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Icon Sizes
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Typography Styles
  static TextStyle get headline1 => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get headline2 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      );

  static TextStyle get headline3 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: -0.2,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textDark,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textDark,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textLight,
        height: 1.4,
      );

  static TextStyle get labelLarge => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textLight,
      );

  // Card Styles
  static BoxDecoration cardDecoration({
    Color? color,
    double? borderRadius,
    double? elevation,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.white,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusL),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.06),
          blurRadius: elevation ?? elevationMedium,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Input Field Decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.darkCyan, size: iconSizeM)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.offWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: AppColors.darkCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: labelLarge.copyWith(color: AppColors.textLight),
      hintStyle: bodyMedium.copyWith(color: AppColors.textLight.withOpacity(0.6)),
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle({
    double? padding,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkCyan,
      foregroundColor: AppColors.white,
      elevation: 0,
      padding: EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: padding ?? spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusM),
      ),
      textStyle: labelLarge.copyWith(color: AppColors.white),
    );
  }

  static ButtonStyle secondaryButtonStyle({
    double? padding,
    double? borderRadius,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.darkCyan,
      side: BorderSide(color: AppColors.darkCyan, width: 2),
      padding: EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: padding ?? spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radiusM),
      ),
      textStyle: labelLarge.copyWith(color: AppColors.darkCyan),
    );
  }

  static ButtonStyle textButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.darkCyan,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingS,
      ),
      textStyle: labelLarge.copyWith(color: AppColors.darkCyan),
    );
  }
}

