import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScreenTimeFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload or update daily screen time
  Future<void> updateDailyScreenTime({
    required String childId,
    required String parentId,
    required int totalScreenTimeMinutes,
    required DateTime date,
  }) async {
    try {
      final dateStr = _formatDate(date);
      final docId = 'screen_time_$dateStr';
      
      final docRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('screenTime')
          .doc(docId);

      await docRef.set({
        'date': Timestamp.fromDate(date),
        'dateString': dateStr,
        'totalScreenTimeMinutes': totalScreenTimeMinutes,
        'totalScreenTimeHours': (totalScreenTimeMinutes / 60).toStringAsFixed(2),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Daily screen time updated: $totalScreenTimeMinutes minutes for $dateStr');
    } catch (e) {
      print('❌ Error updating daily screen time: $e');
      rethrow;
    }
  }

  // Get daily screen time stream
  Stream<Map<String, dynamic>?> getDailyScreenTimeStream({
    required String childId,
    required String parentId,
    required DateTime date,
  }) {
    final dateStr = _formatDate(date);
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
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  // Get weekly screen time
  Future<List<Map<String, dynamic>>> getWeeklyScreenTime({
    required String childId,
    required String parentId,
    required DateTime startDate,
  }) async {
    try {
      final endDate = startDate.add(Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('screenTime')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error getting weekly screen time: $e');
      return [];
    }
  }

  // Calculate and update total screen time from app usage
  Future<void> calculateAndUpdateTotalScreenTime({
    required String childId,
    required String parentId,
    required List<Map<String, dynamic>> appUsageList,
    required DateTime date,
  }) async {
    try {
      // Sum all app usage times (excluding system apps)
      int totalMinutes = 0;
      for (final app in appUsageList) {
        final isSystemApp = app['isSystemApp'] ?? false;
        if (!isSystemApp) {
          totalMinutes += (app['usageDuration'] ?? 0) as int;
        }
      }

      await updateDailyScreenTime(
        childId: childId,
        parentId: parentId,
        totalScreenTimeMinutes: totalMinutes,
        date: date,
      );

      print('✅ Calculated total screen time: $totalMinutes minutes');
    } catch (e) {
      print('❌ Error calculating total screen time: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

