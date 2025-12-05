import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_usage_stats.dart';
import 'local_storage_service.dart';
import '../../../notifications/data/services/notification_integration_service.dart';

class UsageStatsService {
  static const MethodChannel _channel = MethodChannel('usage_stats_service');
  static const MethodChannel _urlChannel = MethodChannel('url_tracking');
  final LocalStorageService _localStorage = LocalStorageService();
  
  // Singleton pattern
  static final UsageStatsService _instance = UsageStatsService._internal();
  factory UsageStatsService() => _instance;
  UsageStatsService._internal();

  /// Check if usage stats permission is granted
  Future<bool> hasUsageStatsPermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasUsageStatsPermission');
      return result;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  /// Request usage stats permission
  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      print('Error requesting usage stats permission: $e');
    }
  }

  /// Get app usage stats for a specific time period
  Future<List<AppUsageStats>> getAppUsageStats({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final List<dynamic> statsData = await _channel.invokeMethod('getAppUsageStats', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      });
      
      return statsData.map((data) => AppUsageStats.fromMap(Map<String, dynamic>.from(data))).toList();
    } catch (e) {
      print('Error getting app usage stats: $e');
      return [];
    }
  }

  /// Get today's app usage stats
  Future<List<AppUsageStats>> getTodayUsageStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final stats = await getAppUsageStats(startTime: startOfDay, endTime: now);
    // Mirror used minutes into local limits store for enforcement hooks
    try {
      final limits = await _localStorage.getAppDailyLimits();
      // Global total
      final totalUsed = stats.fold<int>(0, (total, s) => total + s.foregroundTime.inMinutes);
      await _localStorage.updateGlobalUsedMinutes(totalUsed);
      // DISABLED: Global restriction enforcement
      // final global = await _localStorage.getGlobalDailyLimit();
      // final globalLimit = (global?['dailyLimitMinutes'] ?? 0) as int;
      // if (globalLimit > 0 && totalUsed >= globalLimit) {
      //   final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      //   await setGlobalRestriction(endOfDay);
      // }
      for (final s in stats) {
        if (limits.containsKey(s.packageName)) {
          await _localStorage.updateAppUsage(
            s.packageName,
            s.foregroundTime.inMinutes,
          );
          final item = Map<String, dynamic>.from(limits[s.packageName]);
          final limit = (item['dailyLimitMinutes'] ?? 0) as int;
          if (limit > 0 && s.foregroundTime.inMinutes >= limit) {
            // Enforce restriction until next day
            final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
            await setAppRestriction(s.packageName, endOfDay);
          }
        }
      }
    } catch (_) {}
    return stats;
  }

  Future<void> setGlobalRestriction(DateTime until) async {
    try {
      await _urlChannel.invokeMethod('setGlobalRestriction', {
        'untilMs': until.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error setting global restriction: $e');
    }
  }

  Future<void> clearGlobalRestriction() async {
    try {
      await _urlChannel.invokeMethod('clearGlobalRestriction');
    } catch (e) {
      print('Error clearing global restriction: $e');
    }
  }

  /// Get weekly app usage stats
  Future<List<AppUsageStats>> getWeeklyUsageStats() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return await getAppUsageStats(startTime: weekAgo, endTime: now);
  }

  /// Get daily usage stats for the past week
  Future<Map<DateTime, List<AppUsageStats>>> getDailyUsageStatsForWeek() async {
    final now = DateTime.now();
    final Map<DateTime, List<AppUsageStats>> dailyStats = {};
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      
      final dayStats = await getAppUsageStats(startTime: startOfDay, endTime: endOfDay);
      dailyStats[startOfDay] = dayStats;
    }
    
    return dailyStats;
  }

  /// Get total screen time for today
  Future<Duration> getTodayScreenTime() async {
    try {
      final todayStats = await getTodayUsageStats();
      final totalTime = todayStats.fold<Duration>(
        Duration.zero,
        (total, stat) => total + stat.foregroundTime,
      );
      return totalTime;
    } catch (e) {
      print('Error getting today screen time: $e');
      return Duration.zero;
    }
  }

  /// Get total screen time for the week
  Future<Duration> getWeeklyScreenTime() async {
    try {
      final weekStats = await getWeeklyUsageStats();
      final totalTime = weekStats.fold<Duration>(
        Duration.zero,
        (total, stat) => total + stat.foregroundTime,
      );
      return totalTime;
    } catch (e) {
      print('Error getting weekly screen time: $e');
      return Duration.zero;
    }
  }

  /// Get top used apps for today
  Future<List<AppUsageStats>> getTopUsedAppsToday({int limit = 10}) async {
    final todayStats = await getTodayUsageStats();
    todayStats.sort((a, b) => b.foregroundTime.compareTo(a.foregroundTime));
    return todayStats.take(limit).toList();
  }

  /// Get top used apps for the week
  Future<List<AppUsageStats>> getTopUsedAppsWeek({int limit = 10}) async {
    final weekStats = await getWeeklyUsageStats();
    weekStats.sort((a, b) => b.foregroundTime.compareTo(a.foregroundTime));
    return weekStats.take(limit).toList();
  }

  /// Get app usage stats for a specific app
  Future<AppUsageStats?> getAppUsageStatsForApp(String packageName, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final allStats = await getAppUsageStats(startTime: startTime, endTime: endTime);
      return allStats.firstWhere(
        (stat) => stat.packageName == packageName,
        orElse: () => AppUsageStats(
          packageName: packageName,
          appName: '',
          iconPath: '',
          totalTimeInForeground: Duration.zero,
          lastTimeUsed: DateTime.now(),
          foregroundTime: Duration.zero,
          launchCount: 0,
        ),
      );
    } catch (e) {
      print('Error getting app usage stats for $packageName: $e');
      return null;
    }
  }

  /// Get screen unlock count for today
  Future<int> getTodayUnlockCount() async {
    try {
      final int result = await _channel.invokeMethod('getTodayUnlockCount');
      return result;
    } catch (e) {
      print('Error getting today unlock count: $e');
      return 0;
    }
  }

  /// Get screen unlock count for the week
  Future<int> getWeeklyUnlockCount() async {
    try {
      final int result = await _channel.invokeMethod('getWeeklyUnlockCount');
      return result;
    } catch (e) {
      print('Error getting weekly unlock count: $e');
      return 0;
    }
  }

  /// Get current foreground app
  Future<String?> getCurrentForegroundApp() async {
    try {
      final String? result = await _channel.invokeMethod('getCurrentForegroundApp');
      return result;
    } catch (e) {
      print('Error getting current foreground app: $e');
      return null;
    }
  }

  // Real-time monitoring state
  Timer? _realTimeMonitoringTimer;
  Timer? _realTimeSyncTimer;
  String? _lastForegroundApp;
  bool _isRealTimeMonitoring = false;
  
  /// Start monitoring app usage (for real-time updates)
  Future<void> startMonitoring() async {
    try {
      // Check permission first
      final hasPermission = await hasUsageStatsPermission();
      if (!hasPermission) {
        print('⚠️ [UsageStats] Usage Access permission not granted - real-time monitoring disabled');
        print('⚠️ [UsageStats] Please grant permission to enable real-time tracking');
        return;
      }
      
      await _channel.invokeMethod('startMonitoring');
      
      // Start periodic restriction checking
      _startRestrictionChecker();
      
      // Set up method channel handler for immediate restriction checks
      _setupMethodChannelHandler();
      
      // Start REAL-TIME monitoring (foreground app tracking)
      _startRealTimeMonitoring();
      
      print('✅ [UsageStats] Real-time monitoring started');
    } catch (e) {
      print('❌ [UsageStats] Error starting monitoring: $e');
    }
  }
  
  /// Start real-time foreground app monitoring
  void _startRealTimeMonitoring() {
    if (_isRealTimeMonitoring) {
      print('⚠️ [UsageStats] Real-time monitoring already running');
      return;
    }
    
    _isRealTimeMonitoring = true;
    print('🔄 [UsageStats] Starting real-time foreground app monitoring...');
    
    // Check foreground app every 2 seconds (REAL-TIME)
    _realTimeMonitoringTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final currentApp = await getCurrentForegroundApp();
        
        if (currentApp != null && currentApp != _lastForegroundApp) {
          print('📱 [UsageStats] REAL-TIME: App changed to $currentApp');
          _lastForegroundApp = currentApp;
          
          // CRITICAL: Check app limit immediately when app changes
          print('🔒 [UsageStats] Checking app limit for: $currentApp');
          await checkAppRestrictionImmediately(currentApp);
          
          // You can add Firebase sync here for real-time updates to parent
          // await _syncCurrentAppToFirebase(currentApp);
        }
      } catch (e) {
        print('⚠️ [UsageStats] Error in real-time monitoring: $e');
      }
    });
    
    // Sync usage stats to Firebase every 30 seconds (for parent dashboard)
    _realTimeSyncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        await _syncUsageStatsToFirebase();
      } catch (e) {
        print('⚠️ [UsageStats] Error syncing to Firebase: $e');
      }
    });
    
    print('✅ [UsageStats] Real-time monitoring active (checking every 2s, syncing every 30s)');
  }
  
  /// Sync current usage stats to Firebase for parent dashboard
  Future<void> _syncUsageStatsToFirebase() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final stats = await getAppUsageStats(startTime: startOfDay, endTime: now);
      
      // Get parent and child IDs
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parent_uid');
      final childId = prefs.getString('child_uid');
      
      if (parentId == null || childId == null) {
        return; // Not logged in or not linked
      }
      
      // Sync to Firebase for real-time parent dashboard
      print('📊 [UsageStats] Syncing ${stats.length} apps to Firebase (real-time update)');
      
      final firestore = FirebaseFirestore.instance;
      
      // Sync current app usage stats
      await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('realTimeUsage')
          .doc('current')
          .set({
        'stats': stats.map((s) => s.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'currentApp': _lastForegroundApp,
        'totalScreenTime': stats.fold<int>(0, (sum, s) => sum + s.foregroundTime.inMinutes),
      }, SetOptions(merge: true));
      
      // Also sync current foreground app separately for instant updates
      if (_lastForegroundApp != null) {
        await firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .update({
          'currentForegroundApp': _lastForegroundApp,
          'lastAppUpdate': FieldValue.serverTimestamp(),
        });
      }
      
      print('✅ [UsageStats] Real-time data synced to Firebase');
      
    } catch (e) {
      print('❌ [UsageStats] Error syncing to Firebase: $e');
    }
  }

  /// Set up method channel handler for immediate restriction checks
  void _setupMethodChannelHandler() {
    _urlChannel.setMethodCallHandler((call) async {
      if (call.method == 'checkAppRestrictionImmediately') {
        final packageName = call.arguments['packageName'] as String?;
        if (packageName != null) {
          await checkAppRestrictionImmediately(packageName);
        }
      }
    });
  }

  /// Start periodic restriction checker
  void _startRestrictionChecker() {
    // Check every 1 second for immediate response
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        await _checkAndEnforceRestrictions();
      } catch (e) {
        print('Error in restriction checker: $e');
      }
    });
  }

  /// Check and enforce app restrictions
  Future<void> _checkAndEnforceRestrictions() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final stats = await getAppUsageStats(startTime: startOfDay, endTime: now);
      final limits = await _localStorage.getAppDailyLimits();
      
      for (final stat in stats) {
        if (limits.containsKey(stat.packageName)) {
          // Update usage in local storage
          await _localStorage.updateAppUsage(
            stat.packageName,
            stat.foregroundTime.inMinutes,
          );
          
          final item = Map<String, dynamic>.from(limits[stat.packageName]);
          final limit = (item['dailyLimitMinutes'] ?? 0) as int;
          
          if (limit > 0 && stat.foregroundTime.inMinutes >= limit) {
            // Check if restriction is already set
            final isRestricted = await _urlChannel.invokeMethod('isAppRestricted', {
              'packageName': stat.packageName,
            });
            
            if (isRestricted != true) {
              // Set restriction until next day
              final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
              await setAppRestriction(stat.packageName, endOfDay);
              print('🔒 App ${stat.packageName} restricted until tomorrow due to limit reached (${stat.foregroundTime.inMinutes}min >= ${limit}min)');
              
              // Send notification to parent about screen time limit reached
              await _notifyScreenTimeLimitReached(stat.packageName, limit, stat.foregroundTime.inMinutes);
            }
            
            // Always try to close the app if it's currently in foreground, regardless of restriction status
            try {
              final currentApp = await getCurrentForegroundApp();
              if (currentApp == stat.packageName) {
                print('🚫 IMMEDIATELY CLOSING restricted app: $currentApp (${stat.foregroundTime.inMinutes}min >= ${limit}min)');
                await requestLockNow();
                // Also try to send home action multiple times for better enforcement
                await Future.delayed(const Duration(milliseconds: 500));
                await _urlChannel.invokeMethod('forceCloseApp', {
                  'packageName': stat.packageName,
                });
              }
            } catch (e) {
              print('Error closing restricted app: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error checking restrictions: $e');
    }
  }

  /// Check restrictions for a specific app immediately
  Future<void> checkAppRestrictionImmediately(String packageName) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final stats = await getAppUsageStats(startTime: startOfDay, endTime: now);
      final limits = await _localStorage.getAppDailyLimits();
      
      final stat = stats.firstWhere(
        (s) => s.packageName == packageName,
        orElse: () => AppUsageStats(
          packageName: packageName,
          appName: '',
          iconPath: '',
          totalTimeInForeground: Duration.zero,
          lastTimeUsed: DateTime.now(),
          foregroundTime: Duration.zero,
          launchCount: 0,
        ),
      );
      
      if (limits.containsKey(packageName)) {
        final item = Map<String, dynamic>.from(limits[packageName]);
        final limit = (item['dailyLimitMinutes'] ?? 0) as int;
        
        if (limit > 0 && stat.foregroundTime.inMinutes >= limit) {
          // Set restriction immediately
          final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
          await setAppRestriction(packageName, endOfDay);
          print('🔒 IMMEDIATE RESTRICTION: App $packageName restricted (${stat.foregroundTime.inMinutes}min >= ${limit}min)');
          
          // Try to close the app immediately
          try {
            await requestLockNow();
            print('🚫 Sent lock command for restricted app: $packageName');
          } catch (e) {
            print('Error sending lock command: $e');
          }
        }
      }
    } catch (e) {
      print('Error checking immediate restriction for $packageName: $e');
    }
  }

  /// Notify parent about screen time limit reached
  Future<void> _notifyScreenTimeLimitReached(String packageName, int limit, int currentUsage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parent_uid');
      final childId = prefs.getString('child_uid');

      if (parentId == null || childId == null) {
        print('⚠️ [UsageStats] Parent/Child ID not found for notification');
        return;
      }

      // Get app name from package name
      final stats = await getAppUsageStats(
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now(),
      );
      final appStat = stats.firstWhere(
        (s) => s.packageName == packageName,
        orElse: () => AppUsageStats(
          packageName: packageName,
          appName: packageName,
          iconPath: '',
          totalTimeInForeground: Duration.zero,
          lastTimeUsed: DateTime.now(),
          foregroundTime: Duration.zero,
          launchCount: 0,
        ),
      );

      final notificationService = NotificationIntegrationService();
      await notificationService.onScreenTimeLimitReached(
        parentId: parentId,
        childId: childId,
        dailyLimitMinutes: limit,
        currentUsageMinutes: currentUsage,
      );
      print('✅ [UsageStats] Screen time limit notification sent to parent for ${appStat.appName}');
    } catch (e) {
      print('⚠️ [UsageStats] Error sending screen time limit notification: $e');
    }
  }

  /// Enforce app restriction until a specific time (epoch ms)
  Future<void> setAppRestriction(String packageName, DateTime until) async {
    try {
      await _urlChannel.invokeMethod('setAppRestriction', {
        'packageName': packageName,
        'untilMs': until.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error setting app restriction: $e');
    }
  }

  Future<void> clearAppRestriction(String packageName) async {
    try {
      await _urlChannel.invokeMethod('clearAppRestriction', {
        'packageName': packageName,
      });
    } catch (e) {
      print('Error clearing app restriction: $e');
    }
  }

  Future<void> clearAllRestrictions() async {
    try {
      await _urlChannel.invokeMethod('clearAllRestrictions');
    } catch (e) {
      print('Error clearing all restrictions: $e');
    }
  }

  /// Stop monitoring app usage
  Future<void> stopMonitoring() async {
    try {
      await _channel.invokeMethod('stopMonitoring');
      
      // Stop real-time monitoring
      _realTimeMonitoringTimer?.cancel();
      _realTimeMonitoringTimer = null;
      
      _realTimeSyncTimer?.cancel();
      _realTimeSyncTimer = null;
      
      _isRealTimeMonitoring = false;
      _lastForegroundApp = null;
      
      print('⏹️ [UsageStats] Real-time monitoring stopped');
    } catch (e) {
      print('❌ [UsageStats] Error stopping monitoring: $e');
    }
  }
  
  /// Get current foreground app (real-time)
  Future<String?> getCurrentForegroundAppRealTime() async {
    return await getCurrentForegroundApp();
  }
  
  /// Check if real-time monitoring is active
  bool get isRealTimeMonitoringActive => _isRealTimeMonitoring;

  /// Request immediate lock screen
  Future<void> requestLockNow() async {
    try {
      await _urlChannel.invokeMethod('requestLockNow');
      print('Lock screen requested');
    } catch (e) {
      print('Error requesting lock screen: $e');
    }
  }

  /// Get comprehensive usage report
  Future<Map<String, dynamic>> getUsageReport() async {
    try {
      final todayScreenTime = await getTodayScreenTime();
      final weekScreenTime = await getWeeklyScreenTime();
      final todayUnlocks = await getTodayUnlockCount();
      final weekUnlocks = await getWeeklyUnlockCount();
      final topAppsToday = await getTopUsedAppsToday(limit: 5);
      final topAppsWeek = await getTopUsedAppsWeek(limit: 5);

      return {
        'todayScreenTime': todayScreenTime.inMinutes,
        'weekScreenTime': weekScreenTime.inMinutes,
        'todayUnlocks': todayUnlocks,
        'weekUnlocks': weekUnlocks,
        'topAppsToday': topAppsToday.map((app) => {
          'packageName': app.packageName,
          'appName': app.appName,
          'usageTime': app.foregroundTime.inMinutes,
          'launchCount': app.launchCount,
        }).toList(),
        'topAppsWeek': topAppsWeek.map((app) => {
          'packageName': app.packageName,
          'appName': app.appName,
          'usageTime': app.foregroundTime.inMinutes,
          'launchCount': app.launchCount,
        }).toList(),
      };
    } catch (e) {
      print('Error getting usage report: $e');
      return {};
    }
  }
}