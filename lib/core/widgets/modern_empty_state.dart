import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../design_system/app_design_system.dart';

/// Modern Empty State Component
class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingXL),
              decoration: BoxDecoration(
                color: AppColors.lightCyan.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppDesignSystem.iconSizeXL,
                color: AppColors.darkCyan,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingL),
            Text(
              title,
              style: AppDesignSystem.headline3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDesignSystem.spacingS),
              Text(
                subtitle!,
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDesignSystem.spacingL),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

