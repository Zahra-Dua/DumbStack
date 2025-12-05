import 'package:flutter/material.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/constants/app_text_styles.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';

class ChildLocationInfoCard extends StatelessWidget {
  final ChildLocationEntity location;
  final String childName;

  const ChildLocationInfoCard({
    super.key,
    required this.location,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Child avatar/icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.child_care,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Location info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    childName,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        location.isActive ? Icons.location_on : Icons.location_off,
                        size: 16,
                        color: location.isActive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location.isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.caption.copyWith(
                          color: location.isActive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    _formatTime(location.timestamp),
                    AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.speed,
                    location.speed != null 
                        ? '${(location.speed! * 3.6).toStringAsFixed(1)} km/h'
                        : 'Unknown',
                    AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    Icons.gps_fixed,
                    '±${location.accuracy.toInt()}m accuracy',
                    AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getLocationStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Color _getLocationStatusColor() {
    final now = DateTime.now();
    final locationAge = now.difference(location.timestamp);
    
    if (!location.isActive) {
      return AppColors.error;
    } else if (locationAge.inMinutes < 5) {
      return AppColors.success;
    } else if (locationAge.inMinutes < 15) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
