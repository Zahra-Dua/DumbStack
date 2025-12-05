import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_usage_firebase.dart';
import '../models/installed_app_firebase.dart';
import 'app_limits_firebase_service.dart';

/// Service for Parent to Fetch Child Data from Firebase
/// 
/// This service runs on the parent's device and:
/// - Fetches child's app usage data (sorted by usage time, high to low)
/// - Fetches child's total screen time
/// - Fetches child's installed apps count and list
/// - Provides real-time streams for live updates
class ParentChildDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppLimitsFirebaseService _limitsService = AppLimitsFirebaseService();
  
  /// Get child's app usage data stream (sorted by usage time, high to low)
  Stream<List<AppUsageFirebase>> getChildAppUsageStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('appUsage')
        .orderBy('usageDuration', descending: true) // High to low
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUsageFirebase.fromJson(doc.data()))
          .toList();
    });
  }
  
  /// Get child's today's app usage (sorted by usage time)
  Future<List<AppUsageFirebase>> getChildTodayAppUsage({
    required String childId,
    required String parentId,
  }) async {
    try {
      final now = DateTime.now();
      
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .orderBy('usageDuration', descending: true)
          .get();
      
      final apps = snapshot.docs
          .map((doc) => AppUsageFirebase.fromJson(doc.data()))
          .toList();
      
      // Sort by usage duration (high to low)
      apps.sort((a, b) => b.usageDuration.compareTo(a.usageDuration));
      
      return apps;
    } catch (e) {
      print('❌ [ParentChildDataService] Error getting today app usage: $e');
      return [];
    }
  }
  
  /// Get child's total screen time for today
  Future<int> getChildTodayScreenTime({
    required String childId,
    required String parentId,
  }) async {
    try {
      final now = DateTime.now();
      
      // Get today's screen time document
      final dateStr = _formatDate(now);
      final docId = 'screen_time_$dateStr';
      
      final doc = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('screenTime')
          .doc(docId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        return data?['totalScreenTimeMinutes'] ?? 0;
      }
      
      // If no screen time document, calculate from app usage
      final appUsage = await getChildTodayAppUsage(
        childId: childId,
        parentId: parentId,
      );
      
      final totalMinutes = appUsage.fold<int>(
        0,
        (sum, app) => sum + app.usageDuration,
      );
      
      return totalMinutes;
    } catch (e) {
      print('❌ [ParentChildDataService] Error getting today screen time: $e');
      return 0;
    }
  }
  
  /// Get child's total screen time stream (real-time)
  Stream<int> getChildScreenTimeStream({
    required String childId,
    required String parentId,
  }) {
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final docId = 'screen_time_$dateStr';
    
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('screenTime')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        return data?['totalScreenTimeMinutes'] ?? 0;
      }
      return 0;
    });
  }
  
  /// Get child's installed apps count
  Future<int> getChildInstalledAppsCount({
    required String childId,
    required String parentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('installedApps')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ [ParentChildDataService] Error getting installed apps count: $e');
      return 0;
    }
  }
  
  /// Get child's installed apps stream (real-time)
  Stream<List<InstalledAppFirebase>> getChildInstalledAppsStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('installedApps')
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InstalledAppFirebase.fromJson(doc.data()))
          .toList();
    });
  }
  
  /// Get child's installed apps list
  Future<List<InstalledAppFirebase>> getChildInstalledApps({
    required String childId,
    required String parentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('installedApps')
          .orderBy('detectedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => InstalledAppFirebase.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ [ParentChildDataService] Error getting installed apps: $e');
      return [];
    }
  }
  
  /// Get child's app usage with limits (for parent dashboard)
  Stream<List<Map<String, dynamic>>> getChildAppUsageWithLimitsStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('appUsage')
        .orderBy('usageDuration', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final apps = snapshot.docs
          .map((doc) => AppUsageFirebase.fromJson(doc.data()))
          .toList();
      
      // Get app limits
      final limitsStream = _limitsService.getAppLimitsStream(
        childId: childId,
        parentId: parentId,
      );
      
      final limits = await limitsStream.first;
      final limitsMap = {
        for (var limit in limits)
          limit['packageName']: limit
      };
      
      // Combine app usage with limits
      return apps.map((app) {
        final limit = limitsMap[app.packageName];
        return {
          'app': app,
          'limit': limit,
          'dailyLimitMinutes': limit?['dailyLimitMinutes'] ?? 0,
          'isLimitReached': limit != null && 
              (limit['dailyLimitMinutes'] as int) > 0 &&
              app.usageDuration >= (limit['dailyLimitMinutes'] as int),
        };
      }).toList();
    });
  }
  
  /// Get child's global screen time limit
  Future<Map<String, dynamic>?> getChildGlobalScreenTimeLimit({
    required String childId,
    required String parentId,
  }) async {
    return await _limitsService.getGlobalScreenTimeLimit(
      childId: childId,
      parentId: parentId,
    );
  }
  
  /// Get child's global screen time limit stream
  Stream<Map<String, dynamic>?> getChildGlobalScreenTimeLimitStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data();
      if (data != null && data['globalScreenTimeLimitActive'] == true) {
        return {
          'dailyLimitMinutes': data['globalScreenTimeLimit'] ?? 0,
          'isActive': true,
        };
      }
      return null;
    });
  }
  
  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

