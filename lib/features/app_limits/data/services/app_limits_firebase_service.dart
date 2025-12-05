import 'package:cloud_firestore/cloud_firestore.dart';

class AppLimitsFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Set app limit from parent side
  Future<void> setAppLimit({
    required String childId,
    required String parentId,
    required String packageName,
    required String appName,
    required int dailyLimitMinutes,
  }) async {
    try {
      final limitId = 'limit_$packageName';
      
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appLimits')
          .doc(limitId)
          .set({
        'packageName': packageName,
        'appName': appName,
        'dailyLimitMinutes': dailyLimitMinutes,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ App limit set in Firebase: $appName - $dailyLimitMinutes minutes/day');
    } catch (e) {
      print('❌ Error setting app limit in Firebase: $e');
      rethrow;
    }
  }

  // Get app limit for a specific app
  Future<Map<String, dynamic>?> getAppLimit({
    required String childId,
    required String parentId,
    required String packageName,
  }) async {
    try {
      final limitId = 'limit_$packageName';
      
      final doc = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appLimits')
          .doc(limitId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting app limit from Firebase: $e');
      return null;
    }
  }

  // Get all app limits for a child
  Stream<List<Map<String, dynamic>>> getAppLimitsStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('appLimits')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  // Clear app limit
  Future<void> clearAppLimit({
    required String childId,
    required String parentId,
    required String packageName,
  }) async {
    try {
      final limitId = 'limit_$packageName';
      
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appLimits')
          .doc(limitId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ App limit cleared in Firebase: $packageName');
    } catch (e) {
      print('❌ Error clearing app limit in Firebase: $e');
      rethrow;
    }
  }

  // Set global screen time limit
  Future<void> setGlobalScreenTimeLimit({
    required String childId,
    required String parentId,
    required int dailyLimitMinutes,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .update({
        'globalScreenTimeLimit': dailyLimitMinutes,
        'globalScreenTimeLimitActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Global screen time limit set: $dailyLimitMinutes minutes/day');
    } catch (e) {
      print('❌ Error setting global screen time limit: $e');
      rethrow;
    }
  }

  // Get global screen time limit
  Future<Map<String, dynamic>?> getGlobalScreenTimeLimit({
    required String childId,
    required String parentId,
  }) async {
    try {
      final doc = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();

      final data = doc.data();
      if (data != null && data['globalScreenTimeLimitActive'] == true) {
        return {
          'dailyLimitMinutes': data['globalScreenTimeLimit'] ?? 0,
          'isActive': true,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error getting global screen time limit: $e');
      return null;
    }
  }

  // Clear global screen time limit
  Future<void> clearGlobalScreenTimeLimit({
    required String childId,
    required String parentId,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .update({
        'globalScreenTimeLimitActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Global screen time limit cleared');
    } catch (e) {
      print('❌ Error clearing global screen time limit: $e');
      rethrow;
    }
  }
}

