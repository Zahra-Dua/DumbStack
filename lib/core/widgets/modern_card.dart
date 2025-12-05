import 'package:flutter/material.dart';
import '../design_system/app_design_system.dart';
import '../constants/app_colors.dart';

/// Modern Card Component with consistent styling
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool showShadow;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppDesignSystem.spacingM),
      padding: padding ?? const EdgeInsets.all(AppDesignSystem.spacingL),
      decoration: AppDesignSystem.cardDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: borderRadius ?? AppDesignSystem.radiusL,
        elevation: showShadow ? AppDesignSystem.elevationMedium : 0,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDesignSystem.radiusL,
        ),
        child: card,
      );
    }

    return card;
  }
}

