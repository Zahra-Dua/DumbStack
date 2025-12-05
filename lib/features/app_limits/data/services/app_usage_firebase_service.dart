import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_usage_firebase.dart';

class AppUsageFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload app usage to Firebase
  Future<void> uploadAppUsageToFirebase({
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
      final appId = 'app_${packageName}_${DateTime.now().millisecondsSinceEpoch}';
      
      final appUsage = AppUsageFirebase(
        id: appId,
        packageName: packageName,
        appName: appName,
        usageDuration: usageDuration,
        launchCount: launchCount,
        lastUsed: lastUsed,
        appIcon: appIcon,
        metadata: metadata,
        isSystemApp: isSystemApp,
        riskScore: riskScore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .doc(appId)
          .set(appUsage.toJson());

      print('✅ App usage uploaded to Firebase: $appName');
    } catch (e) {
      print('❌ Error uploading app usage to Firebase: $e');
      rethrow;
    }
  }

  // Update app usage in Firebase
  Future<void> updateAppUsageInFirebase({
    required String childId,
    required String parentId,
    required String appId,
    required int usageDuration,
    required int launchCount,
    required DateTime lastUsed,
    double? riskScore,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .doc(appId)
          .update({
        'usageDuration': usageDuration,
        'launchCount': launchCount,
        'lastUsed': Timestamp.fromDate(lastUsed),
        'riskScore': riskScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ App usage updated in Firebase: $appId');
    } catch (e) {
      print('❌ Error updating app usage in Firebase: $e');
      rethrow;
    }
  }

  // Batch upload multiple app usages
  Future<void> batchUploadAppUsage({
    required List<AppUsageFirebase> appUsages,
    required String childId,
    required String parentId,
  }) async {
    if (appUsages.isEmpty) return;

    try {
      final batch = _firestore.batch();
      
      for (final appUsage in appUsages) {
        final docRef = _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('appUsage')
            .doc(appUsage.id);
        
        batch.set(docRef, appUsage.toJson());
      }

      await batch.commit();
      print('✅ Batch uploaded ${appUsages.length} app usages to Firebase');
    } catch (e) {
      print('❌ Error batch uploading app usages: $e');
      rethrow;
    }
  }

  // Get current user info
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
