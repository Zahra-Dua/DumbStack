import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ChildPermissionService {
  static const MethodChannel _channel = MethodChannel('child_tracking');

  // Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final permissions = [
      Permission.systemAlertWindow,
      Permission.ignoreBatteryOptimizations,
      Permission.notification,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    // Check usage stats permission separately (Usage Access)
    final usageStatsGranted = await checkUsageStatsPermission();
    
    // Check accessibility permission separately
    final accessibilityGranted = await checkAccessibilityPermission();
    
    // Both permissions are required for app_limits and url_tracking
    return usageStatsGranted && accessibilityGranted;
  }

  // Request all required permissions
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    try {
      // Request system alert window
      final systemAlertStatus = await Permission.systemAlertWindow.request();
      results['system_alert'] = systemAlertStatus == PermissionStatus.granted;

      // Request battery optimization ignore
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      results['battery'] = batteryStatus == PermissionStatus.granted;

      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      results['notification'] = notificationStatus == PermissionStatus.granted;

      // Request usage stats permission (special handling - opens settings)
      await requestUsageStatsPermission();
      // Wait a moment for user to enable in settings
      await Future.delayed(const Duration(milliseconds: 500));
      results['usage_stats'] = await checkUsageStatsPermission();

      // Request accessibility permission (special handling - opens settings)
      await requestAccessibilityPermission();
      results['accessibility'] = await checkAccessibilityPermission();

      return results;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return results;
    }
  }

  // Check usage stats permission
  static Future<bool> checkUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod('checkUsageStatsPermission');
      return result == true;
    } catch (e) {
      print('❌ Error checking usage stats permission: $e');
      return false;
    }
  }

  // Private method for internal use
  static Future<bool> _checkUsageStatsPermission() async {
    return await checkUsageStatsPermission();
  }

  // Request usage stats permission
  static Future<bool> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
      return true;
    } catch (e) {
      print('❌ Error requesting usage stats permission: $e');
      return false;
    }
  }

  // Private method for internal use
  static Future<bool> _requestUsageStatsPermission() async {
    return await requestUsageStatsPermission();
  }

  // Check accessibility permission
  static Future<bool> checkAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod('checkAccessibilityPermission');
      return result == true;
    } catch (e) {
      print('❌ Error checking accessibility permission: $e');
      return false;
    }
  }

  // Request accessibility permission
  static Future<bool> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
      return true;
    } catch (e) {
      print('❌ Error requesting accessibility permission: $e');
      return false;
    }
  }

  // Start URL tracking service
  static Future<bool> startUrlTracking() async {
    try {
      final result = await _channel.invokeMethod('startUrlTracking');
      return result == true;
    } catch (e) {
      print('❌ Error starting URL tracking: $e');
      return false;
    }
  }

  // Start app usage tracking
  static Future<bool> startAppUsageTracking() async {
    try {
      final result = await _channel.invokeMethod('startAppUsageTracking');
      return result == true;
    } catch (e) {
      print('❌ Error starting app usage tracking: $e');
      return false;
    }
  }

  // Stop all tracking services
  static Future<bool> stopAllTracking() async {
    try {
      final result = await _channel.invokeMethod('stopAllTracking');
      return result == true;
    } catch (e) {
      print('❌ Error stopping tracking: $e');
      return false;
    }
  }

  // Get device info for tracking setup
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      return {
        'deviceId': androidInfo.id,
        'model': androidInfo.model,
        'brand': androidInfo.brand,
        'version': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'isPhysicalDevice': androidInfo.isPhysicalDevice,
      };
    } catch (e) {
      print('❌ Error getting device info: $e');
      return {};
    }
  }

  // Check if device supports required features
  static Future<bool> isDeviceCompatible() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final sdkInt = deviceInfo['sdkInt'] as int?;
      
      // Require Android 6.0 (API 23) or higher for accessibility services
      return sdkInt != null && sdkInt >= 23;
    } catch (e) {
      print('❌ Error checking device compatibility: $e');
      return false;
    }
  }
}
