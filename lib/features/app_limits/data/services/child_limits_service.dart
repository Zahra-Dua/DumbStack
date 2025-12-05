import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for Child Device to Fetch Limits from Firebase
/// 
/// This service runs on the child's device and:
/// - Fetches app limits set by parent
/// - Fetches global screen time limit set by parent
/// - Provides real-time streams for live updates
class ChildLimitsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _childId;
  String? _parentId;
  
  /// Initialize with child and parent IDs
  void initialize({required String childId, required String parentId}) {
    _childId = childId;
    _parentId = parentId;
    print('✅ [ChildLimitsService] Initialized for child: $childId');
  }
  
  /// Get app limit for a specific app
  Future<Map<String, dynamic>?> getAppLimit(String packageName) async {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildLimitsService] Not initialized');
      return null;
    }
    
    try {
      final limitId = 'limit_$packageName';
      
      final doc = await _firestore
          .collection('parents')
          .doc(_parentId)
          .collection('children')
          .doc(_childId)
          .collection('appLimits')
          .doc(limitId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['isActive'] == true) {
          return {
            'packageName': packageName,
            'dailyLimitMinutes': data['dailyLimitMinutes'] ?? 0,
            'isActive': true,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ [ChildLimitsService] Error getting app limit: $e');
      return null;
    }
  }
  
  /// Get all app limits stream (real-time)
  Stream<List<Map<String, dynamic>>> getAppLimitsStream() {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildLimitsService] Not initialized');
      return Stream.value([]);
    }
    
    return _firestore
        .collection('parents')
        .doc(_parentId!)
        .collection('children')
        .doc(_childId!)
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
  
  /// Get global screen time limit
  Future<Map<String, dynamic>?> getGlobalScreenTimeLimit() async {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildLimitsService] Not initialized');
      return null;
    }
    
    try {
      final doc = await _firestore
          .collection('parents')
          .doc(_parentId)
          .collection('children')
          .doc(_childId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['globalScreenTimeLimitActive'] == true) {
          return {
            'dailyLimitMinutes': data['globalScreenTimeLimit'] ?? 0,
            'isActive': true,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ [ChildLimitsService] Error getting global screen time limit: $e');
      return null;
    }
  }
  
  /// Get global screen time limit stream (real-time)
  Stream<Map<String, dynamic>?> getGlobalScreenTimeLimitStream() {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildLimitsService] Not initialized');
      return Stream.value(null);
    }
    
    return _firestore
        .collection('parents')
        .doc(_parentId!)
        .collection('children')
        .doc(_childId!)
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
  
  /// Get today's screen time
  Future<int> getTodayScreenTime() async {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildLimitsService] Not initialized');
      return 0;
    }
    
    try {
      final now = DateTime.now();
      final dateStr = _formatDate(now);
      final docId = 'screen_time_$dateStr';
      
      final doc = await _firestore
          .collection('parents')
          .doc(_parentId)
          .collection('children')
          .doc(_childId)
          .collection('screenTime')
          .doc(docId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        return data?['totalScreenTimeMinutes'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ [ChildLimitsService] Error getting today screen time: $e');
      return 0;
    }
  }
  
  /// Get today's screen time stream (real-time)
  Stream<int> getTodayScreenTimeStream() {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildLimitsService] Not initialized');
      return Stream.value(0);
    }
    
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final docId = 'screen_time_$dateStr';
    
    return _firestore
        .collection('parents')
        .doc(_parentId!)
        .collection('children')
        .doc(_childId!)
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
  
  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Dispose
  void dispose() {
    _childId = null;
    _parentId = null;
  }
}

