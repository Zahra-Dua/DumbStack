import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/alert_type.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  IconData _getIconForAlertType(AlertType type) {
    switch (type) {
      case AlertType.suspiciousMessage:
        return Icons.message;
      case AlertType.suspiciousCall:
        return Icons.phone;
      case AlertType.geofencing:
        return Icons.location_on;
      case AlertType.sos:
        return Icons.emergency;
      case AlertType.screenTimeLimit:
        return Icons.timer;
      case AlertType.appWebsiteBlocked:
        return Icons.block;
      case AlertType.emotionalDistress:
        return Icons.mood_bad;
      case AlertType.toxicBehaviorPattern:
        return Icons.warning;
      case AlertType.suspiciousContactsPattern:
        return Icons.contacts;
      case AlertType.predictiveThreat:
        return Icons.psychology;
      case AlertType.general:
        return Icons.notifications;
    }
  }

  Color _getColorForAlertType(AlertType type) {
    switch (type) {
      case AlertType.sos:
        return Colors.red;
      case AlertType.suspiciousMessage:
      case AlertType.suspiciousCall:
        return Colors.orange;
      case AlertType.geofencing:
        return Colors.blue;
      case AlertType.emotionalDistress:
      case AlertType.toxicBehaviorPattern:
        return Colors.purple;
      case AlertType.predictiveThreat:
        return Colors.deepOrange;
      default:
        return AppColors.darkCyan;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getColorForAlertType(notification.alertType);
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isUnread ? 2 : 1,
      color: isUnread ? Colors.white : Colors.grey[50],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForAlertType(notification.alertType),
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.darkCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

