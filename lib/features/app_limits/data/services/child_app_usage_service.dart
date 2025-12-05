import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_usage_firebase.dart';
import 'app_usage_firebase_service.dart';

class ChildAppUsageService {
  final AppUsageFirebaseService _firebaseService = AppUsageFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload app usage when child uses an app
  Future<void> uploadAppUsage({
    required String packageName,
    required String appName,
    required int usageDuration,
    required int launchCount,
    required DateTime lastUsed,
    required String childId,
    required String parentId,
    String? appIcon,
    Map<String, dynamic>? metadata,
    bool isSystemApp = false,
    double? riskScore,
  }) async {
    try {
      await _firebaseService.uploadAppUsageToFirebase(
        packageName: packageName,
        appName: appName,
        usageDuration: usageDuration,
        launchCount: launchCount,
        lastUsed: lastUsed,
        childId: childId,
        parentId: parentId,
        appIcon: appIcon,
        metadata: metadata,
        isSystemApp: isSystemApp,
        riskScore: riskScore,
      );
      
      print('✅ Child app usage uploaded to Firebase: $appName');
    } catch (e) {
      print('❌ Error uploading child app usage: $e');
      // Don't rethrow - we don't want to break the child's app usage
    }
  }

  // Update existing app usage
  Future<void> updateAppUsage({
    required String childId,
    required String parentId,
    required String appId,
    required int usageDuration,
    required int launchCount,
    required DateTime lastUsed,
    double? riskScore,
  }) async {
    try {
      await _firebaseService.updateAppUsageInFirebase(
        childId: childId,
        parentId: parentId,
        appId: appId,
        usageDuration: usageDuration,
        launchCount: launchCount,
        lastUsed: lastUsed,
        riskScore: riskScore,
      );
      
      print('✅ Child app usage updated in Firebase: $appId');
    } catch (e) {
      print('❌ Error updating child app usage: $e');
    }
  }

  // Batch upload multiple app usages
  Future<void> batchUploadAppUsage({
    required List<Map<String, dynamic>> appUsages,
    required String childId,
    required String parentId,
  }) async {
    try {
      final appUsageObjects = appUsages.map((appData) => AppUsageFirebase(
        id: 'app_${appData['packageName']}_${DateTime.now().millisecondsSinceEpoch}',
        packageName: appData['packageName'] ?? '',
        appName: appData['appName'] ?? '',
        usageDuration: appData['usageDuration'] ?? 0,
        launchCount: appData['launchCount'] ?? 0,
        lastUsed: appData['lastUsed'] ?? DateTime.now(),
        appIcon: appData['appIcon'],
        metadata: appData['metadata'],
        isSystemApp: appData['isSystemApp'] ?? false,
        riskScore: appData['riskScore']?.toDouble(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();

      await _firebaseService.batchUploadAppUsage(
        appUsages: appUsageObjects,
        childId: childId,
        parentId: parentId,
      );
      
      print('✅ Child batch uploaded ${appUsages.length} app usages to Firebase');
    } catch (e) {
      print('❌ Error batch uploading child app usages: $e');
    }
  }

  // Get current child ID
  String? getCurrentChildId() {
    return _auth.currentUser?.uid;
  }

  // Get parent ID
  Future<String?> getParentId(String childId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('child_parent_mapping')
          .doc(childId)
          .get();
      
      return doc.data()?['parentId'];
    } catch (e) {
      print('❌ Error getting parent ID: $e');
      return null;
    }
  }
}
