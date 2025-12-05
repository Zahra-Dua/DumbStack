import 'package:flutter/material.dart';
import '../../data/services/url_blocking_firebase_service.dart';
import '../../data/models/blocked_url_rule.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/design_system/app_design_system.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/modern_app_bar.dart';

/// Screen for parent to view and manage blocked URLs
class BlockedUrlsScreen extends StatefulWidget {
  final String childId;
  final String parentId;

  const BlockedUrlsScreen({
    super.key,
    required this.childId,
    required this.parentId,
  });

  @override
  State<BlockedUrlsScreen> createState() => _BlockedUrlsScreenState();
}

class _BlockedUrlsScreenState extends State<BlockedUrlsScreen> {
  final UrlBlockingFirebaseService _blockingService = UrlBlockingFirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: const ModernAppBar(
        title: 'Blocked URLs',
      ),
      body: StreamBuilder<List<BlockedUrlRule>>(
        stream: _blockingService.getBlockedUrlsStream(
          childId: widget.childId,
          parentId: widget.parentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDesignSystem.spacingM),
                  Text(
                    'Error loading blocked URLs',
                    style: AppDesignSystem.headline3,
                  ),
                ],
              ),
            );
          }

          final blockedUrls = snapshot.data ?? [];

          if (blockedUrls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: AppDesignSystem.spacingM),
                  Text(
                    'No URLs blocked yet',
                    style: AppDesignSystem.headline3,
                  ),
                  const SizedBox(height: AppDesignSystem.spacingS),
                  Text(
                    'Block URLs from the URL History screen',
                    style: AppDesignSystem.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDesignSystem.spacingL),
            itemCount: blockedUrls.length,
            itemBuilder: (context, index) {
              final rule = blockedUrls[index];
              return ModernCard(
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
                            borderRadius: BorderRadius.circular(
                              AppDesignSystem.radiusS,
                            ),
                          ),
                          child: Icon(
                            Icons.block_rounded,
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
                                rule.url,
                                style: AppDesignSystem.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (rule.domain != null) ...[
                                const SizedBox(height: AppDesignSystem.spacingXS),
                              Text(
                                'Domain: ${rule.domain}',
                                style: AppDesignSystem.bodySmall,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_rounded,
                            color: AppColors.error,
                          ),
                          onPressed: () => _unblockUrl(rule),
                        ),
                      ],
                    ),
                    if (rule.reason != null) ...[
                      const SizedBox(height: AppDesignSystem.spacingM),
                      Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.warning,
                              size: AppDesignSystem.iconSizeS,
                            ),
                            const SizedBox(width: AppDesignSystem.spacingS),
                            Expanded(
                              child: Text(
                                rule.reason!,
                                style: AppDesignSystem.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDesignSystem.spacingS),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: AppDesignSystem.iconSizeS,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: AppDesignSystem.spacingXS),
                        Flexible(
                          child: Text(
                            'Blocked ${_formatDateTime(rule.blockedAt)}',
                            style: AppDesignSystem.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppDesignSystem.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDesignSystem.spacingS,
                            vertical: AppDesignSystem.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDesignSystem.radiusRound,
                            ),
                          ),
                          child: Text(
                            rule.blockType.toString().split('.').last.toUpperCase(),
                            style: AppDesignSystem.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _unblockUrl(BlockedUrlRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unblock URL',
          style: AppDesignSystem.headline3,
        ),
        content: Text(
          'Are you sure you want to unblock this URL?\n\n${rule.url}',
          style: AppDesignSystem.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppDesignSystem.labelLarge.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: AppDesignSystem.primaryButtonStyle(),
            child: Text(
              'Unblock',
              style: AppDesignSystem.labelLarge.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _blockingService.unblockUrl(
          childId: widget.childId,
          parentId: widget.parentId,
          urlId: rule.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('URL unblocked successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error unblocking URL: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              ),
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

