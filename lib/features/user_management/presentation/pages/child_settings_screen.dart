import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/design_system/app_design_system.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../child_tracking/data/services/child_permission_service.dart';

class ChildSettingsScreen extends StatefulWidget {
  const ChildSettingsScreen({super.key});

  @override
  State<ChildSettingsScreen> createState() => _ChildSettingsScreenState();
}

class _ChildSettingsScreenState extends State<ChildSettingsScreen> with SingleTickerProviderStateMixin {
  final Map<Permission, bool> _permissionsStatus = {};
  bool _accessibilityGranted = false;
  bool _usageAccessGranted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _checkPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.location,
      Permission.sms,
      Permission.phone,
      Permission.notification,
      Permission.systemAlertWindow,
      Permission.ignoreBatteryOptimizations,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      _permissionsStatus[permission] = status.isGranted;
    }
    
    _accessibilityGranted = await ChildPermissionService.checkAccessibilityPermission();
    _usageAccessGranted = await ChildPermissionService.checkUsageStatsPermission();
    
    if (mounted) setState(() {});
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required Color iconColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDesignSystem.headline3.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppDesignSystem.bodySmall.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGranted ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: isGranted ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isGranted ? 'Granted' : 'Not Granted',
                    style: AppDesignSystem.labelSmall.copyWith(
                      color: isGranted ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Settings',
              style: AppDesignSystem.headline1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Permissions & Access',
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Permissions List
            _buildPermissionCard(
              title: 'Location',
              description: 'Track device location for safety',
              icon: Icons.location_on_rounded,
              isGranted: _permissionsStatus[Permission.location] ?? false,
              iconColor: AppColors.darkCyan,
            ),
            
            _buildPermissionCard(
              title: 'SMS Messages',
              description: 'Monitor text messages for safety',
              icon: Icons.message_rounded,
              isGranted: _permissionsStatus[Permission.sms] ?? false,
              iconColor: AppColors.brightTeal,
            ),
            
            _buildPermissionCard(
              title: 'Phone Access',
              description: 'Monitor phone calls and contacts',
              icon: Icons.phone_rounded,
              isGranted: _permissionsStatus[Permission.phone] ?? false,
              iconColor: AppColors.success,
            ),
            
            _buildPermissionCard(
              title: 'Notifications',
              description: 'Alert on geofence and messages',
              icon: Icons.notifications_rounded,
              isGranted: _permissionsStatus[Permission.notification] ?? false,
              iconColor: AppColors.warning,
            ),
            
            _buildPermissionCard(
              title: 'System Alert',
              description: 'System-level monitoring',
              icon: Icons.security_rounded,
              isGranted: _permissionsStatus[Permission.systemAlertWindow] ?? false,
              iconColor: AppColors.error,
            ),
            
            _buildPermissionCard(
              title: 'Battery Optimization',
              description: 'Run in background for monitoring',
              icon: Icons.battery_charging_full_rounded,
              isGranted: _permissionsStatus[Permission.ignoreBatteryOptimizations] ?? false,
              iconColor: AppColors.deepTeal,
            ),
            
            _buildPermissionCard(
              title: 'Accessibility Service',
              description: 'Track app usage and URLs',
              icon: Icons.accessibility_rounded,
              isGranted: _accessibilityGranted,
              iconColor: AppColors.darkCyan,
            ),
            
            _buildPermissionCard(
              title: 'Usage Access',
              description: 'App limits and usage tracking',
              icon: Icons.analytics_rounded,
              isGranted: _usageAccessGranted,
              iconColor: AppColors.brightTeal,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

