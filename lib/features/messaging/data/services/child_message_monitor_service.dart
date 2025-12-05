// lib/features/messages/services/child_message_monitor_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/message_remote_datasource.dart';

/// Simple message monitoring service without background tasks
class ChildMessageMonitorService {
  final MessageRemoteDataSourceImpl dataSource;
  Timer? _timer;
  
  ChildMessageMonitorService({required this.dataSource});

  /// Start periodic message monitoring
  Future<void> initialize({int frequencySeconds = 5}) async {
    print('🚀 [ChildMonitor] Starting message monitoring (every $frequencySeconds seconds)');
    
    // Start monitoring immediately
    await _monitorMessages();
    
    // Set up periodic monitoring
    _timer = Timer.periodic(Duration(seconds: frequencySeconds), (timer) {
      _monitorMessages();
    });
    
    print('✅ [ChildMonitor] Message monitoring started');
  }

  /// Monitor messages for the current user
  Future<void> _monitorMessages() async {
    try {
      print('🔔 [ChildMonitor] Starting message monitoring cycle');
      
      // Read saved IDs
      final prefs = await SharedPreferences.getInstance();
      String? parentId = prefs.getString('parent_uid');
      String? childId = prefs.getString('child_uid');

      print('🔍 [ChildMonitor] parent_uid: $parentId, child_uid: $childId');

      if (parentId == null || childId == null) {
        print('❌ [ChildMonitor] parent_uid or child_uid missing - using test values');
        print('❌ [ChildMonitor] Available keys: ${prefs.getKeys()}');
        print('🧪 [ChildMonitor] Using test parent and child IDs for message monitoring');
        
        // Use test values for monitoring
        parentId = 'test_parent_id';
        childId = 'test_child_id';
      }

      // At this point, both parentId and childId are guaranteed to be non-null
      // Assign to non-nullable variables for type safety
      final String nonNullParentId = parentId;
      final String nonNullChildId = childId;

      // Check if child is linked before monitoring
      final isLinked = await dataSource.isChildLinkedToParent(
        parentId: nonNullParentId, 
        childId: nonNullChildId
      );
      
      print('🔗 [ChildMonitor] Child linked to parent: $isLinked');
      
      if (!isLinked) {
        print('⚠️ [ChildMonitor] Child not linked to parent yet - skipping monitoring');
        return;
      }

      // Add small delay to prevent permission conflicts
      await Future.delayed(Duration(milliseconds: 500));

      print('🚀 [ChildMonitor] Calling monitorChildMessages...');
      
      // Call monitor
      await dataSource.monitorChildMessages(parentId: nonNullParentId, childId: nonNullChildId);

      print('✅ [ChildMonitor] Message monitoring cycle completed');
    } catch (e, st) {
      print('❌ [ChildMonitor] Message monitoring error: $e\n$st');
      // Don't crash the app, just log the error
      if (e.toString().contains('Reply already submitted')) {
        print('⚠️ [ChildMonitor] Permission handling conflict - will retry next cycle');
      }
    }
  }

  /// Stop monitoring
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    print('🛑 [ChildMonitor] Message monitoring stopped');
  }
}