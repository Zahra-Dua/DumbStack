import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/features/user_management/presentation/pages/child_scan_qr_screen.dart';
import 'package:parental_control_app/features/child_tracking/data/services/child_permission_service.dart';

class ChildPermissionsScreen extends StatefulWidget {
  const ChildPermissionsScreen({super.key});

  @override
  State<ChildPermissionsScreen> createState() => _ChildPermissionsScreenState();
}

class _ChildPermissionsScreenState extends State<ChildPermissionsScreen> with WidgetsBindingObserver {
  final Map<Permission, bool> _permissionsStatus = {
    Permission.phone: false,
    Permission.sms: false,
    Permission.location: false,
    Permission.notification: false,
    Permission.systemAlertWindow: false,
    Permission.ignoreBatteryOptimizations: false,
  };
  
  bool _accessibilityGranted = false;
  bool _usageAccessGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh permissions when app resumes (user might have enabled permissions in Settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    for (final permission in _permissionsStatus.keys) {
      final status = await permission.status;
      _permissionsStatus[permission] = status.isGranted;
    }
    
    // Check accessibility and usage access permissions
    _accessibilityGranted = await ChildPermissionService.checkAccessibilityPermission();
    _usageAccessGranted = await ChildPermissionService.checkUsageStatsPermission();
    
    if (mounted) setState(() {});
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    _permissionsStatus[permission] = status.isGranted;
    if (mounted) setState(() {});
  }

  Future<void> _requestAccessibilityPermission() async {
    await ChildPermissionService.requestAccessibilityPermission();
    // Wait a bit for user to enable it in settings, then check again
    await Future.delayed(const Duration(seconds: 1));
    _accessibilityGranted = await ChildPermissionService.checkAccessibilityPermission();
    if (mounted) setState(() {});
  }

  Future<void> _requestUsageAccessPermission() async {
    await ChildPermissionService.requestUsageStatsPermission();
    // Wait a bit for user to enable it in settings, then check again
    await Future.delayed(const Duration(seconds: 1));
    _usageAccessGranted = await ChildPermissionService.checkUsageStatsPermission();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              'SafeNest',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mq.w(0.06)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: mq.h(0.02)),
              Text(
                'Allow Access',
                style: TextStyle(
                  fontSize: mq.sp(0.07),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: mq.h(0.02)),
              Text(
                'To enable SafeNest\'s features allow access to your child\'s data for monitoring.',
                style: TextStyle(
                  fontSize: mq.sp(0.04),
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: mq.h(0.04)),
              
              // Permissions List
              Container(
                padding: EdgeInsets.all(mq.w(0.04)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                        _buildPermissionItem(
                          'Location',
                          'Track device location for safety (enable background for geofencing)',
                          Icons.location_on,
                          Permission.location,
                        ),
                        const Divider(),
                        _buildPermissionItem(
                          'SMS Messages',
                          'Monitor text messages for safety and inappropriate content',
                          Icons.message,
                          Permission.sms,
                        ),
                        const Divider(),
                        _buildPermissionItem(
                          'Phone Access',
                          'Monitor phone calls and contacts for safety',
                          Icons.phone,
                          Permission.phone,
                        ),
                        const Divider(),
                        _buildPermissionItem(
                          'Notifications',
                          'Used to alert on geofence entry/exit and message monitoring',
                          Icons.notifications,
                          Permission.notification,
                        ),
                        const Divider(),
                        _buildPermissionItem(
                          'System Alert',
                          'Allow system-level monitoring for comprehensive safety',
                          Icons.security,
                          Permission.systemAlertWindow,
                        ),
                        const Divider(),
                        _buildSpecialPermissionItem(
                          'Accessibility Service',
                          'Required to track app usage and URLs for monitoring. Enable in Settings > Accessibility',
                          Icons.accessibility,
                          _accessibilityGranted,
                          () => _requestAccessibilityPermission(),
                        ),
                        const Divider(),
                        _buildSpecialPermissionItem(
                          'Usage Access',
                          'Required for app limits and usage tracking. Enable in Settings > Apps > Special app access > Usage access',
                          Icons.analytics,
                          _usageAccessGranted,
                          () => _requestUsageAccessPermission(),
                        ),
                        const Divider(),
                        _buildPermissionItem(
                          'Battery Optimization',
                          'Allow app to run in background for continuous monitoring',
                          Icons.battery_charging_full,
                          Permission.ignoreBatteryOptimizations,
                        ),
                  ],
                ),
              ),
              
              SizedBox(height: mq.h(0.04)),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCyan,
                    padding: EdgeInsets.symmetric(vertical: mq.h(0.018)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: mq.sp(0.04),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: mq.h(0.02)), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String title, String subtitle, IconData icon, Permission permission) {
    final granted = _permissionsStatus[permission] ?? false;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.darkCyan),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: granted,
          onChanged: (_) => _requestPermission(permission),
        ),
      ),
    );
  }

  Widget _buildSpecialPermissionItem(
    String title,
    String subtitle,
    IconData icon,
    bool granted,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.darkCyan),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: granted,
          onChanged: (_) => onTap(),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    try {
      // Request all permissions
      print('🔐 REQUESTING PERMISSIONS: Starting permission requests...');
      
      for (final entry in _permissionsStatus.entries) {
        if (entry.value) {
          print('   Requesting ${entry.key}: ${entry.value}');
          final status = await entry.key.request();
          print('   Result: ${status.isGranted ? "GRANTED" : "DENIED"}');
        }
      }

      // Request accessibility and usage access permissions if not granted
      if (!_accessibilityGranted) {
        await ChildPermissionService.requestAccessibilityPermission();
        await Future.delayed(const Duration(seconds: 1));
        _accessibilityGranted = await ChildPermissionService.checkAccessibilityPermission();
      }
      
      if (!_usageAccessGranted) {
        await ChildPermissionService.requestUsageStatsPermission();
        await Future.delayed(const Duration(seconds: 1));
        _usageAccessGranted = await ChildPermissionService.checkUsageStatsPermission();
      }

      // Check if critical permissions are granted
      final smsGranted = await Permission.sms.isGranted;
      final phoneGranted = await Permission.phone.isGranted;
      final accessibilityGranted = await ChildPermissionService.checkAccessibilityPermission();
      final usageAccessGranted = await ChildPermissionService.checkUsageStatsPermission();
      final batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;
      
      print('📊 PERMISSION STATUS:');
      print('   SMS: ${smsGranted ? "GRANTED" : "DENIED"}');
      print('   Phone: ${phoneGranted ? "GRANTED" : "DENIED"}');
      print('   Accessibility: ${accessibilityGranted ? "GRANTED" : "DENIED"}');
      print('   Usage Access: ${usageAccessGranted ? "GRANTED" : "DENIED"}');
      print('   Battery: ${batteryGranted ? "GRANTED" : "DENIED"}');

      if (smsGranted && phoneGranted && accessibilityGranted && usageAccessGranted) {
        print('✅ PERMISSIONS GRANTED: Starting message monitoring initialization...');
        
        // Initialize message monitoring
        await _initializeMessageMonitoring();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions configured successfully! Message monitoring started.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('⚠️ PERMISSIONS PARTIAL: Some permissions not granted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Some permissions were not granted. Message monitoring may be limited.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Navigate to child home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChildHomeScreen()),
      );
    } catch (e) {
      print('❌ PERMISSION ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error configuring permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeMessageMonitoring() async {
    try {
      print('🚀 INITIALIZING TRACKING SERVICES: Starting after permissions...');
      
      // Start URL tracking
      final urlTrackingStarted = await ChildPermissionService.startUrlTracking();
      print('   URL Tracking: ${urlTrackingStarted ? "STARTED" : "FAILED"}');
      
      // Start app usage tracking
      final appTrackingStarted = await ChildPermissionService.startAppUsageTracking();
      print('   App Usage Tracking: ${appTrackingStarted ? "STARTED" : "FAILED"}');
      
      print('✅ TRACKING SERVICES: Initialized successfully');
    } catch (e) {
      print('❌ TRACKING SERVICES ERROR: $e');
    }
  }
}
