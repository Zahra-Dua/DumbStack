import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../url_tracking/data/models/visited_url_firebase.dart';
import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../app_limits/data/models/installed_app_firebase.dart';
import '../../../app_limits/data/services/screen_time_firebase_service.dart';

class ParentDashboardFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScreenTimeFirebaseService _screenTimeService = ScreenTimeFirebaseService();

  // Get visited URLs for a child
  Stream<List<VisitedUrlFirebase>> getVisitedUrlsStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('visitedUrls')
        .orderBy('visitedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VisitedUrlFirebase.fromJson(doc.data()))
          .toList();
    });
  }

  // Get app usage for a child
  Stream<List<AppUsageFirebase>> getAppUsageStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('appUsage')
        .orderBy('lastUsed', descending: true)
        .snapshots()
        .map((snapshot) {
      final apps = snapshot.docs
          .map((doc) => AppUsageFirebase.fromJson(doc.data()))
          .toList();
      
      // Calculate and update total screen time
      _updateTotalScreenTime(childId: childId, parentId: parentId, apps: apps);
      
      return apps;
    });
  }

  // Update total screen time based on app usage
  Future<void> _updateTotalScreenTime({
    required String childId,
    required String parentId,
    required List<AppUsageFirebase> apps,
  }) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      // Filter apps used today and exclude system apps
      final todayApps = apps.where((app) {
        final isToday = app.lastUsed.isAfter(todayStart);
        final isUserApp = !app.isSystemApp;
        return isToday && isUserApp;
      }).toList();
      
      // Calculate total screen time for today
      final totalMinutes = todayApps.fold<int>(0, (sum, app) => sum + app.usageDuration);
      
      // Update screen time in Firebase
      await _screenTimeService.updateDailyScreenTime(
        childId: childId,
        parentId: parentId,
        totalScreenTimeMinutes: totalMinutes,
        date: todayStart,
      );
    } catch (e) {
      print('❌ Error updating total screen time: $e');
    }
  }

  // Get today's total screen time
  Stream<int> getTodayScreenTimeStream({
    required String childId,
    required String parentId,
  }) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return _screenTimeService.getDailyScreenTimeStream(
      childId: childId,
      parentId: parentId,
      date: todayStart,
    ).map((data) {
      if (data == null) return 0;
      return (data['totalScreenTimeMinutes'] ?? 0) as int;
    });
  }

  // Get today's app usage summary
  Future<Map<String, dynamic>> getTodayAppUsageSummary({
    required String childId,
    required String parentId,
  }) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .where('lastUsed', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('lastUsed', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      int totalUsageMinutes = 0;
      int totalLaunches = 0;
      int totalApps = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalUsageMinutes += ((data['usageDuration'] ?? 0) as num).toInt();
        totalLaunches += ((data['launchCount'] ?? 0) as num).toInt();
        totalApps++;
      }

      return {
        'totalUsageMinutes': totalUsageMinutes,
        'totalLaunches': totalLaunches,
        'totalApps': totalApps,
        'screenTime': _formatDuration(totalUsageMinutes),
      };
    } catch (e) {
      print('❌ Error getting today app usage summary: $e');
      return {
        'totalUsageMinutes': 0,
        'totalLaunches': 0,
        'totalApps': 0,
        'screenTime': '0m',
      };
    }
  }

  // Get this week's app usage summary
  Future<Map<String, dynamic>> getWeekAppUsageSummary({
    required String childId,
    required String parentId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .where('lastUsed', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDay))
          .get();

      int totalUsageMinutes = 0;
      int totalLaunches = 0;
      int totalApps = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalUsageMinutes += ((data['usageDuration'] ?? 0) as num).toInt();
        totalLaunches += ((data['launchCount'] ?? 0) as num).toInt();
        totalApps++;
      }

      return {
        'totalUsageMinutes': totalUsageMinutes,
        'totalLaunches': totalLaunches,
        'totalApps': totalApps,
        'screenTime': _formatDuration(totalUsageMinutes),
      };
    } catch (e) {
      print('❌ Error getting week app usage summary: $e');
      return {
        'totalUsageMinutes': 0,
        'totalLaunches': 0,
        'totalApps': 0,
        'screenTime': '0m',
      };
    }
  }

  // Get daily screen time for the week
  Future<List<Map<String, dynamic>>> getDailyScreenTime({
    required String childId,
    required String parentId,
  }) async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> dailyData = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(Duration(days: 1));

        final snapshot = await _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('appUsage')
            .where('lastUsed', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('lastUsed', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        int totalMinutes = 0;
        for (final doc in snapshot.docs) {
          totalMinutes += ((doc.data()['usageDuration'] ?? 0) as num).toInt();
        }

        dailyData.add({
          'date': date,
          'dayName': _getDayName(date.weekday),
          'totalMinutes': totalMinutes,
          'totalHours': (totalMinutes / 60).toStringAsFixed(1),
        });
      }

      return dailyData;
    } catch (e) {
      print('❌ Error getting daily screen time: $e');
      return [];
    }
  }

  // Get most used apps
  Future<List<AppUsageFirebase>> getMostUsedApps({
    required String childId,
    required String parentId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .orderBy('usageDuration', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AppUsageFirebase.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting most used apps: $e');
      return [];
    }
  }

  // Update URL block status
  Future<void> updateUrlBlockStatus({
    required String childId,
    required String parentId,
    required String urlId,
    required bool isBlocked,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .doc(urlId)
          .update({
        'isBlocked': isBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating URL block status: $e');
      rethrow;
    }
  }

  // Delete URL
  Future<void> deleteUrl({
    required String childId,
    required String parentId,
    required String urlId,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .doc(urlId)
          .delete();
      print('✅ URL deleted successfully: $urlId');
    } catch (e) {
      print('❌ Error deleting URL: $e');
      rethrow;
    }
  }

  // Block/Unblock App
  Future<void> updateAppBlockStatus({
    required String childId,
    required String parentId,
    required String packageName,
    required bool isBlocked,
  }) async {
    try {
      // Update in appUsage collection
      final appUsageSnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .where('packageName', isEqualTo: packageName)
          .get();

      final batch = _firestore.batch();
      for (final doc in appUsageSnapshot.docs) {
        batch.update(doc.reference, {
          'isBlocked': isBlocked,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Also store in blockedApps collection for quick lookup
      final blockedAppRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('blockedApps')
          .doc(packageName);

      if (isBlocked) {
        batch.set(blockedAppRef, {
          'packageName': packageName,
          'isBlocked': true,
          'blockedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.delete(blockedAppRef);
      }

      await batch.commit();
      print('✅ App block status updated: $packageName -> $isBlocked');
    } catch (e) {
      print('❌ Error updating app block status: $e');
      rethrow;
    }
  }

  // Get blocked apps stream
  Stream<List<String>> getBlockedAppsStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('blockedApps')
        .where('isBlocked', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['packageName'] as String)
          .toList();
    });
  }

  // Helper methods
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Get installed apps for a child
  Stream<List<InstalledAppFirebase>> getInstalledAppsStream({
    required String childId,
    required String parentId,
  }) {
    print('📱 [ParentDashboardFirebaseService] Fetching installed apps stream');
    print('   Child ID: $childId');
    print('   Parent ID: $parentId');
    print('   Path: parents/$parentId/children/$childId/installedApps');
    
    try {
      return _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('installedApps')
          .snapshots()
          .map((snapshot) {
        print('📱 [ParentDashboardFirebaseService] Installed apps snapshot received: ${snapshot.docs.length} apps');
        
        final apps = snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                print('   ✅ App: ${data['appName'] ?? 'Unknown'} (${data['packageName'] ?? 'Unknown'})');
                return InstalledAppFirebase.fromJson(data);
              } catch (e) {
                print('❌ Error parsing app ${doc.id}: $e');
                print('   Data: ${doc.data()}');
                return null;
              }
            })
            .where((app) => app != null)
            .cast<InstalledAppFirebase>()
            .toList();
        
        // Sort by detectedAt descending (most recent first)
        apps.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
        
        print('✅ [ParentDashboardFirebaseService] Parsed ${apps.length} installed apps');
        return apps;
      }).handleError((error) {
        print('❌ [ParentDashboardFirebaseService] Error in installed apps stream: $error');
        print('   Stack trace: ${StackTrace.current}');
        return <InstalledAppFirebase>[];
      });
    } catch (e) {
      print('❌ [ParentDashboardFirebaseService] Error setting up installed apps stream: $e');
      return Stream.value(<InstalledAppFirebase>[]);
    }
  }

  // Get newly installed apps
  Future<List<InstalledAppFirebase>> getNewlyInstalledApps({
    required String childId,
    required String parentId,
    int days = 7,
  }) async {
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('installedApps')
          .where('isNewInstallation', isEqualTo: true)
          .where('detectedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('detectedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InstalledAppFirebase.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting newly installed apps: $e');
      return [];
    }
  }

  // Get current user info
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
