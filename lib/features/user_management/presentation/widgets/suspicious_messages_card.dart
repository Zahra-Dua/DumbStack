import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/design_system/app_design_system.dart';
import '../../../../core/widgets/modern_card.dart';

class SuspiciousMessagesCard extends StatelessWidget {
  final int suspiciousCount;
  final VoidCallback? onTap;

  const SuspiciousMessagesCard({
    super.key,
    required this.suspiciousCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDesignSystem.spacingL),
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: AppColors.error,
                  size: AppDesignSystem.iconSizeM,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suspicious Messages',
                      style: AppDesignSystem.headline3,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXS),
                    Text(
                      'Potential threats detected',
                      style: AppDesignSystem.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacingM,
                  vertical: AppDesignSystem.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: suspiciousCount > 0 ? AppColors.error : AppColors.success,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusRound),
                ),
                child: Text(
                  suspiciousCount > 0 ? '$suspiciousCount Alert${suspiciousCount > 1 ? 's' : ''}' : 'Safe',
                  style: AppDesignSystem.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          if (suspiciousCount > 0) ...[
            const SizedBox(height: AppDesignSystem.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingM),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.error,
                    size: AppDesignSystem.iconSizeM,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingM),
                  Expanded(
                    child: Text(
                      'Review messages for potential threats and inappropriate content',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: AppDesignSystem.spacingM),
          
          Row(
            children: [
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.darkCyan,
                size: AppDesignSystem.iconSizeS,
              ),
              const SizedBox(width: AppDesignSystem.spacingS),
              Text(
                'Tap to view messages',
                style: AppDesignSystem.bodyMedium.copyWith(
                  color: AppColors.darkCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
