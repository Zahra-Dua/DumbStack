import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/call_log_remote_datasource.dart';
import 'suspicious_call_detector_service.dart';

/// Simple call log monitoring service
/// No background listeners - only foreground scanning
class CallLogMonitorService {
  final CallLogRemoteDataSourceImpl dataSource;
  Timer? _timer;
  bool _isPeriodicScanActive = false;

  CallLogMonitorService({required this.dataSource});

  /// Simple scan: Fetch call logs and check for suspicious calls
  /// No background timer - just scan when called
  Future<void> scanCallLogs() async {
    print('🔍 [CallLogMonitor] Starting call log scan...');
    await _monitorCallLogs();
  }
  
  /// Optional: Periodic scan (foreground only - stops when app goes to background)
  /// [frequencySeconds] - how often to scan (default: 30 seconds)
  /// ⚠️ IMPORTANT: Call stopPeriodicScan() when app goes to background
  Future<void> startPeriodicScan({int frequencySeconds = 30}) async {
    if (_isPeriodicScanActive) {
      print('⚙️ [CallLogMonitor] Periodic scan already active');
      return;
    }
    
    print('🚀 [CallLogMonitor] Starting periodic scan (every $frequencySeconds seconds)');
    print('   ⚠️ Note: This runs only when app is in foreground');
    print('   ⚠️ IMPORTANT: Call stopPeriodicScan() when app goes to background');
    
    _isPeriodicScanActive = true;
    await _monitorCallLogs();
    
    _timer = Timer.periodic(Duration(seconds: frequencySeconds), (timer) {
      if (!_isPeriodicScanActive) {
        timer.cancel();
        return;
      }
      _monitorCallLogs();
    });
    
    print('✅ [CallLogMonitor] Periodic scan started');
  }
  
  /// Stop periodic scan (call when app goes to background)
  void stopPeriodicScan() {
    if (!_isPeriodicScanActive) {
      return;
    }
    
    print('🛑 [CallLogMonitor] Stopping periodic scan (app going to background)');
    _timer?.cancel();
    _timer = null;
    _isPeriodicScanActive = false;
    print('✅ [CallLogMonitor] Periodic scan stopped');
  }

  Future<void> _monitorCallLogs() async {
    try {
      print('🔔 [CallLogMonitor] Starting call log monitoring cycle');
      final prefs = await SharedPreferences.getInstance();
      String? parentId = prefs.getString('parent_uid');
      String? childId = prefs.getString('child_uid');

      print('🔍 [CallLogMonitor] parent_uid: $parentId, child_uid: $childId');

      if (parentId == null || childId == null) {
        print('❌ [CallLogMonitor] parent_uid or child_uid missing - skipping call log monitoring');
        return;
      }

      final isLinked = await dataSource.firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get()
          .then((doc) => doc.exists);

      print('🔗 [CallLogMonitor] Child linked to parent: $isLinked');

      if (!isLinked) {
        print('⚠️ [CallLogMonitor] Child not linked to parent yet - skipping call log monitoring');
        return;
      }

      await Future.delayed(Duration(milliseconds: 500)); // Delay to prevent permission conflicts
      
      // ✅ Run suspicious call detector (analyzes unknown contacts, odd hours, etc.)
      // Simple approach: Scan last 24 hours and apply rules
      print('🚀 [CallLogMonitor] Starting suspicious call detection...');
      final detector = SuspiciousCallDetectorService(
        firestore: dataSource.firestore,
        childId: childId,
        parentId: parentId,
      );
      await detector.scanCallLogs(); // Simple scan - no background listener
      print('✅ [CallLogMonitor] Suspicious call detection completed');
      
      // Also upload call logs to Firebase (for call history screen)
      print('🚀 [CallLogMonitor] Uploading call logs to Firebase...');
      await dataSource.monitorChildCallLogs(parentId: parentId, childId: childId);
      print('✅ [CallLogMonitor] Call log monitoring cycle completed');
    } catch (e, st) {
      print('❌ [CallLogMonitor] Call log monitoring error: $e\n$st');
      if (e.toString().contains('Reply already submitted')) {
        print('⚠️ [CallLogMonitor] Permission handling conflict - will retry next cycle');
      }
    }
  }

  /// Stop all monitoring (cleanup)
  Future<void> stop() async {
    stopPeriodicScan();
    print('🛑 [CallLogMonitor] Call log monitoring stopped');
  }
  
  /// Dispose resources
  void dispose() {
    stopPeriodicScan();
  }
}
