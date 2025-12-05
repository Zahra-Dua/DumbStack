import 'package:flutter/material.dart';
import '../design_system/app_design_system.dart';
import '../constants/app_colors.dart';

/// Modern Button Component with consistent styling
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: AppDesignSystem.primaryButtonStyle(),
          child: _buildButtonContent(),
        );
        break;
      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: AppDesignSystem.secondaryButtonStyle(),
          child: _buildButtonContent(),
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: AppDesignSystem.textButtonStyle(),
          child: _buildButtonContent(),
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: width ?? double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      Color indicatorColor = AppColors.white;
      if (type == ButtonType.secondary) {
        indicatorColor = AppColors.darkCyan;
      } else if (type == ButtonType.text) {
        indicatorColor = AppColors.darkCyan;
      }
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }

    TextStyle textStyle = AppDesignSystem.labelLarge.copyWith(
      color: type == ButtonType.primary
          ? AppColors.white
          : AppColors.darkCyan,
    );

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppDesignSystem.iconSizeM,
            color: type == ButtonType.primary
                ? AppColors.white
                : AppColors.darkCyan,
          ),
          const SizedBox(width: AppDesignSystem.spacingS),
          Text(text, style: textStyle),
        ],
      );
    }

    return Text(text, style: textStyle);
  }
}

enum ButtonType { primary, secondary, text }

