import 'package:flutter/services.dart';
import '../models/installed_app.dart';

/// AppListService - Uses Native Android Method Channel (QUERY_ALL_PACKAGES solution)
/// 
/// This service uses native Kotlin code via method channel to get ALL installed apps.
/// Works with QUERY_ALL_PACKAGES permission for complete app list.
class AppListService {
  static const MethodChannel _channel = MethodChannel('app_list_service');

  /// Get list of all installed apps on the device (Native Method Channel)
  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      print('📱 [AppListService] ========== GETTING INSTALLED APPS ==========');
      print('📱 [AppListService] Using NATIVE method channel (app_list_service)...');
      print('📱 [AppListService] This uses QUERY_ALL_PACKAGES permission solution');
      
      // Get all installed apps from native Android code
      final startTime = DateTime.now();
      final List<dynamic> rawList = await _channel.invokeMethod('getInstalledApps');
      final duration = DateTime.now().difference(startTime);
      
      print('📱 [AppListService] ✅ Received ${rawList.length} apps from native Android');
      print('📱 [AppListService] ⏱️ Time taken: ${duration.inMilliseconds}ms');
      
      if (rawList.isEmpty) {
        print('⚠️ [AppListService] ⚠️⚠️⚠️ WARNING: EMPTY APP LIST RECEIVED! ⚠️⚠️⚠️');
        print('⚠️ [AppListService] This might indicate:');
        print('   1. QUERY_ALL_PACKAGES permission not granted');
        print('   2. Native method channel error');
        print('   3. Device compatibility issue');
        print('⚠️ [AppListService] Check AndroidManifest.xml for QUERY_ALL_PACKAGES permission');
        return [];
      }
      
      // Convert to InstalledApp model
      print('📱 [AppListService] Converting ${rawList.length} apps to InstalledApp model...');
      final List<InstalledApp> installedApps = rawList.map((data) {
        final map = Map<String, dynamic>.from(data);
        return InstalledApp(
          packageName: map['packageName'] ?? '',
          appName: map['appName'] ?? 'Unknown',
          versionName: map['versionName'],
          versionCode: map['versionCode']?.toInt() ?? 0,
          isSystemApp: map['isSystemApp'] ?? false,
          installTime: DateTime.fromMillisecondsSinceEpoch(
            map['installTime'] ?? DateTime.now().millisecondsSinceEpoch,
          ),
          lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
            map['lastUpdateTime'] ?? DateTime.now().millisecondsSinceEpoch,
          ),
          iconPath: map['iconPath'],
        );
      }).toList();
      
      // Count system vs user apps
      final systemAppsCount = installedApps.where((app) => app.isSystemApp).length;
      final userAppsCount = installedApps.length - systemAppsCount;
      print('📱 [AppListService] Breakdown:');
      print('   - Total Apps: ${installedApps.length}');
      print('   - User Apps: $userAppsCount');
      print('   - System Apps: $systemAppsCount');
      
      // Print first 10 apps for debugging
      print('📱 [AppListService] Sample apps (first 10):');
      for (var i = 0; i < (installedApps.length > 10 ? 10 : installedApps.length); i++) {
        final app = installedApps[i];
        print('   ${i + 1}. ${app.appName} (${app.packageName}) [${app.isSystemApp ? "System" : "User"}]');
      }
      
      print('✅ [AppListService] Successfully converted ${installedApps.length} apps to InstalledApp model');
      print('📱 [AppListService] ============================================');
      return installedApps;
    } catch (e, stackTrace) {
      print('❌ [AppListService] ========== ERROR GETTING APPS ==========');
      print('❌ [AppListService] Error: $e');
      print('❌ [AppListService] Stack trace: $stackTrace');
      print('❌ [AppListService] Make sure:');
      print('   1. QUERY_ALL_PACKAGES permission is in AndroidManifest.xml');
      print('   2. AppListPlugin.kt is registered in MainActivity.kt');
      print('   3. Native method channel "app_list_service" is working');
      print('❌ [AppListService] =========================================');
      return [];
    }
  }

  /// Get list of user-installed apps (excluding system apps) - Native Method Channel
  Future<List<InstalledApp>> getUserApps() async {
    try {
      print('📱 [AppListService] Getting user apps only (native)...');
      
      final List<dynamic> rawList = await _channel.invokeMethod('getUserApps');
      
      return rawList.map((data) {
        final map = Map<String, dynamic>.from(data);
        return InstalledApp(
          packageName: map['packageName'] ?? '',
          appName: map['appName'] ?? 'Unknown',
          versionName: map['versionName'],
          versionCode: map['versionCode']?.toInt() ?? 0,
          isSystemApp: false,
          installTime: DateTime.fromMillisecondsSinceEpoch(
            map['installTime'] ?? DateTime.now().millisecondsSinceEpoch,
          ),
          lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
            map['lastUpdateTime'] ?? DateTime.now().millisecondsSinceEpoch,
          ),
          iconPath: map['iconPath'],
        );
      }).toList();
    } catch (e, stackTrace) {
      print('❌ [AppListService] Error getting user apps: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get list of system apps only - Native Method Channel
  Future<List<InstalledApp>> getSystemApps() async {
    try {
      print('📱 [AppListService] Getting system apps only (native)...');
      
      final List<dynamic> rawList = await _channel.invokeMethod('getSystemApps');
      
      return rawList.map((data) {
        final map = Map<String, dynamic>.from(data);
        return InstalledApp(
          packageName: map['packageName'] ?? '',
          appName: map['appName'] ?? 'Unknown',
          versionName: map['versionName'],
          versionCode: map['versionCode']?.toInt() ?? 0,
          isSystemApp: true,
          installTime: DateTime.fromMillisecondsSinceEpoch(
            map['installTime'] ?? DateTime.now().millisecondsSinceEpoch,
          ),
          lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
            map['lastUpdateTime'] ?? DateTime.now().millisecondsSinceEpoch,
          ),
          iconPath: map['iconPath'],
        );
      }).toList();
    } catch (e, stackTrace) {
      print('❌ [AppListService] Error getting system apps: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Launch an app by package name - Native Method Channel
  Future<bool> launchApp(String packageName) async {
    try {
      print('🚀 [AppListService] Launching app: $packageName');
      final bool launched = await _channel.invokeMethod('launchApp', {'packageName': packageName});
      if (launched) {
        print('✅ [AppListService] App launched successfully: $packageName');
      } else {
        print('❌ [AppListService] Failed to launch app: $packageName');
      }
      return launched;
    } catch (e) {
      print('❌ [AppListService] Error launching app: $e');
      return false;
    }
  }

  /// Uninstall an app by package name - Native Method Channel
  Future<bool> uninstallApp(String packageName) async {
    try {
      print('🗑️ [AppListService] Uninstalling app: $packageName');
      final bool uninstalled = await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
      if (uninstalled) {
        print('✅ [AppListService] App uninstalled successfully: $packageName');
      } else {
        print('❌ [AppListService] Failed to uninstall app: $packageName');
      }
      return uninstalled;
    } catch (e) {
      print('❌ [AppListService] Error uninstalling app: $e');
      return false;
    }
  }

  /// Get app info by package name - Native Method Channel
  Future<InstalledApp?> getAppInfo(String packageName) async {
    try {
      print('📱 [AppListService] Getting app info: $packageName');
      final Map<dynamic, dynamic>? appData = await _channel.invokeMethod('getAppInfo', {'packageName': packageName});
      
      if (appData == null) {
        print('⚠️ [AppListService] App not found: $packageName');
        return null;
      }
      
      final map = Map<String, dynamic>.from(appData);
      return InstalledApp(
        packageName: map['packageName'] ?? '',
        appName: map['appName'] ?? 'Unknown',
        versionName: map['versionName'],
        versionCode: map['versionCode']?.toInt() ?? 0,
        isSystemApp: map['isSystemApp'] ?? false,
        installTime: DateTime.fromMillisecondsSinceEpoch(
          map['installTime'] ?? DateTime.now().millisecondsSinceEpoch,
        ),
        lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
          map['lastUpdateTime'] ?? DateTime.now().millisecondsSinceEpoch,
        ),
        iconPath: map['iconPath'],
      );
    } catch (e) {
      print('❌ [AppListService] Error getting app info: $e');
      return null;
    }
  }

  /// Check if an app is installed - Native Method Channel
  Future<bool> isAppInstalled(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('isAppInstalled', {'packageName': packageName});
      return result;
    } catch (e) {
      print('❌ [AppListService] Error checking if app is installed: $e');
      return false;
    }
  }
}
