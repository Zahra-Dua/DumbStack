import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:call_log/call_log.dart';
import '../models/call_log_model.dart';

class FlaggedCallsRemoteDataSource {
  final FirebaseFirestore firestore;

  FlaggedCallsRemoteDataSource({required this.firestore});

  /// Fetch flagged calls for parent view (last 24 hours)
  Future<List<CallLogModel>> getFlaggedCalls({
    required String parentId,
    required String childId,
  }) async {
    try {
      print('📥 [FlaggedCallsRemote] Fetching flagged calls...');
      print('   Path: parents/$parentId/children/$childId/flagged_calls');
      
      // Fetch all flagged calls (last 24 hours)
      final last24h = DateTime.now().subtract(const Duration(hours: 24));
      final last24hMs = last24h.millisecondsSinceEpoch;
      
      final snapshot = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_calls')
          .where('dateTime', isGreaterThanOrEqualTo: last24hMs)
          .orderBy('dateTime', descending: true)
          .get();

      print('   Raw Firestore docs: ${snapshot.docs.length}');
      
      final flaggedCalls = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return CallLogModel(
            id: data['id'] ?? doc.id,
            name: data['name'],
            number: data['number'] ?? 'Unknown',
            simDisplayName: data['simDisplayName'],
            duration: data['duration'] ?? 0,
            dateTime: DateTime.fromMillisecondsSinceEpoch(data['dateTime'] ?? 0),
            type: _parseCallType(data['type']),
            childId: data['childId'] ?? childId,
            parentId: data['parentId'] ?? parentId,
            uploadedAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          );
        } catch (e) {
          print('   ❌ Error parsing doc ${doc.id}: $e');
          return null;
        }
      }).whereType<CallLogModel>().toList();
      
      print('✅ [FlaggedCallsRemote] Loaded ${flaggedCalls.length} flagged calls from last 24h');
      return flaggedCalls;
    } catch (e) {
      print('❌ [FlaggedCallsRemote] Error fetching flagged calls: $e');
      return [];
    }
  }

  /// Stream of flagged calls for real-time updates
  Stream<List<CallLogModel>> getFlaggedCallsStream({
    required String parentId,
    required String childId,
  }) {
    print('🔔 [FlaggedCallsRemote] Setting up stream for flagged calls...');
    
    final last24h = DateTime.now().subtract(const Duration(hours: 24));
    final last24hMs = last24h.millisecondsSinceEpoch;
    
    return firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('flagged_calls')
        .where('dateTime', isGreaterThanOrEqualTo: last24hMs)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📥 [FlaggedCallsRemote] Stream update: ${snapshot.docs.length} flagged calls');
      
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return CallLogModel(
            id: data['id'] ?? doc.id,
            name: data['name'],
            number: data['number'] ?? 'Unknown',
            simDisplayName: data['simDisplayName'],
            duration: data['duration'] ?? 0,
            dateTime: DateTime.fromMillisecondsSinceEpoch(data['dateTime'] ?? 0),
            type: _parseCallType(data['type']),
            childId: data['childId'] ?? childId,
            parentId: data['parentId'] ?? parentId,
            uploadedAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          );
        } catch (e) {
          print('   ❌ Error parsing doc ${doc.id}: $e');
          return null;
        }
      }).whereType<CallLogModel>().toList();
    });
  }

  /// Get count of flagged calls
  Future<int> getFlaggedCallsCount({
    required String parentId,
    required String childId,
  }) async {
    try {
      final last24h = DateTime.now().subtract(const Duration(hours: 24));
      final last24hMs = last24h.millisecondsSinceEpoch;
      
      final snapshot = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_calls')
          .where('dateTime', isGreaterThanOrEqualTo: last24hMs)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ [FlaggedCallsRemote] Error getting flagged calls count: $e');
      return 0;
    }
  }

  /// Parse CallType from string
  CallType _parseCallType(dynamic type) {
    if (type == null) return CallType.outgoing;
    final typeStr = type.toString();
    if (typeStr.contains('incoming')) return CallType.incoming;
    if (typeStr.contains('outgoing')) return CallType.outgoing;
    if (typeStr.contains('missed')) return CallType.missed;
    if (typeStr.contains('rejected')) return CallType.rejected;
    if (typeStr.contains('blocked')) return CallType.blocked;
    return CallType.outgoing;
  }
}

