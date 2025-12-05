import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/design_system/app_design_system.dart';

/// Warning page shown when child tries to access a blocked URL
class BlockedUrlWarningPage extends StatelessWidget {
  final String blockedUrl;
  final String? reason;

  const BlockedUrlWarningPage({
    super.key,
    required this.blockedUrl,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Warning Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingXL),
                
                // Title
                Text(
                  'Access Blocked',
                  style: AppDesignSystem.headline1.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesignSystem.spacingM),
                
                // Message
                Text(
                  'This website has been blocked by your parent.',
                  style: AppDesignSystem.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDesignSystem.spacingL),
                
                // Blocked URL
                Container(
                  padding: const EdgeInsets.all(AppDesignSystem.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: AppColors.textLight,
                        size: AppDesignSystem.iconSizeM,
                      ),
                      const SizedBox(width: AppDesignSystem.spacingM),
                      Expanded(
                        child: Text(
                          blockedUrl,
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (reason != null) ...[
                  const SizedBox(height: AppDesignSystem.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.warning,
                          size: AppDesignSystem.iconSizeM,
                        ),
                        const SizedBox(width: AppDesignSystem.spacingM),
                        Expanded(
                          child: Text(
                            reason!,
                            style: AppDesignSystem.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: AppDesignSystem.spacingXXL),
                
                // Go Back Button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppDesignSystem.primaryButtonStyle(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded),
                      const SizedBox(width: AppDesignSystem.spacingS),
                      Text(
                        'Go Back',
                        style: AppDesignSystem.labelLarge.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

