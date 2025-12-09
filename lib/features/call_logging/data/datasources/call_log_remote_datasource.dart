import 'dart:async';
import 'package:call_log/call_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_log_model.dart';

class CallLogRemoteDataSourceImpl {
  final FirebaseFirestore firestore;
  Timer? _monitorTimer;
  bool _isRunning = false;

  CallLogRemoteDataSourceImpl({required this.firestore});

  /// 🔁 Start background call log monitoring every 10 seconds (REAL-TIME detection)
  /// CallLog API doesn't provide direct listeners, so we poll every 10 seconds
  /// This ensures new calls are detected almost instantly (industry standard approach)
  void startContinuousMonitoring({
    required String parentId,
    required String childId,
  }) {
    if (_isRunning) {
      print('⚙️ [CallMonitor] Already running, skipping duplicate start');
      return;
    }

    print('');
    print('📞 ========== 📞 STARTING CALL LOG MONITORING 📞 ==========');
    print('📞 [CallMonitor] Starting REAL-TIME call log monitoring (every 10 seconds)...');
    print('📞 [CallMonitor] Parent ID: $parentId');
    print('📞 [CallMonitor] Child ID: $childId');
    print('📞 [CallMonitor] New calls will be detected within 10 seconds');
    print('📞 [CallMonitor] Firebase path: parents/$parentId/children/$childId/call_logs');
    print('📞 ====================================================');
    print('');
    _isRunning = true;

    // Run immediately once, then every 10 seconds (almost real-time)
    print('📞 [CallMonitor] Running first check immediately...');
    monitorChildCallLogs(parentId: parentId, childId: childId);
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      print('📞 [CallMonitor] Periodic check (every 10 seconds)...');
      monitorChildCallLogs(parentId: parentId, childId: childId);
    });
  }

  /// 🛑 Stop background monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _isRunning = false;
    print('🛑 [CallMonitor] Call log monitoring stopped.');
  }

  /// 🧹 Force reset and process all recent call logs
  Future<void> forceResetAndProcess(String parentId, String childId) async {
    print('🔄 [CallLogRemote] Force resetting and processing all recent call logs...');
    
    // Reset timestamp to 0 to force reprocessing
    final prefs = await SharedPreferences.getInstance();
    final lastTsKey = 'last_call_log_timestamp_$childId';
    await prefs.setInt(lastTsKey, 0);
    
    // Process all call logs from last 1 day
    await monitorChildCallLogs(parentId: parentId, childId: childId);
    
    print('✅ [CallLogRemote] Force reset and process completed');
  }

  /// 🔄 Reset call log timestamp for testing
  Future<void> resetCallLogTimestamp(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTsKey = 'last_call_log_timestamp_$childId';
    await prefs.setInt(lastTsKey, 0); // Set to 0 instead of removing
    print('🔄 [CallLogRemote] Call log timestamp reset to 0 for child: $childId');
  }

  /// 📞 Main monitor called every 5 minutes
  Future<void> monitorChildCallLogs({
    required String parentId,
    required String childId,
  }) async {
    print('\n📞 [CallLogRemote] Checking new call logs for child: $childId');

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTsKey = 'last_call_log_timestamp_$childId';
      int lastTimestamp = prefs.getInt(lastTsKey) ?? 0;

      // ✅ Fetch call logs with error handling first
      List<CallLogEntry> callLogList = [];
      try {
        print('📞 [CallLogRemote] Attempting to fetch call logs from device...');
        final Iterable<CallLogEntry> callLogs = await CallLog.get();
        // OPTIMIZATION: Sort by timestamp (newest first) for early exit
        callLogList = callLogs.toList()
          ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
        print('📞 [CallLogRemote] ✅ Total call logs fetched: ${callLogList.length} (sorted newest first)');
        
        if (callLogList.isEmpty) {
          print('⚠️ [CallLogRemote] No call logs found. This could be due to:');
          print('   1. No call history on device');
          print('   2. Missing READ_CALL_LOG permission');
          print('   3. Device restrictions');
          print('⚠️ [CallLogRemote] Please check if READ_CALL_LOG permission is granted');
        } else {
          print('📞 [CallLogRemote] Found ${callLogList.length} call logs on device');
        }
      } catch (e) {
        print('❌ [CallLogRemote] Error fetching call logs: $e');
        print('🔍 [CallLogRemote] This might be due to missing permissions or no call logs');
        print('🔍 [CallLogRemote] Make sure READ_CALL_LOG permission is granted');
        print('🔍 [CallLogRemote] Stack trace: ${StackTrace.current}');
        return;
      }

      // Check if timestamp is corrupted (future or negative values only)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const allowedFutureDriftMs = 60000; // allow 60s clock skew
      if (lastTimestamp > currentTime + allowedFutureDriftMs || lastTimestamp < 0) {
        print('⚠️ [CallLogRemote] Corrupted timestamp detected: $lastTimestamp (current: $currentTime)');
        print('   Reason: timestamp is ${lastTimestamp < 0 ? 'negative' : 'in the future'}');
        print('🔄 [CallLogRemote] Resetting timestamp...');
        lastTimestamp = 0;
        await prefs.setInt(lastTsKey, 0);
        print('ℹ️ [CallLogRemote] Timestamp reset to 0 - will re-initialize on next run');
        
        // Process recent call logs immediately
        await _processRecentCallLogs(parentId, childId);
        return;
      }

      // 🕐 First-time setup - Process ONLY last 24 hours of call logs (NOT old 2-3 day calls)
      if (lastTimestamp == 0) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
        
        print('🕐 [CallLogRemote] First run detected → Processing ONLY last 24 hours of call logs');
        print('📅 [CallLogRemote] Processing calls from: ${DateTime.fromMillisecondsSinceEpoch(twentyFourHoursAgo)}');
        print('📅 [CallLogRemote] Processing calls until: ${DateTime.fromMillisecondsSinceEpoch(now)}');
        print('⚠️ [CallLogRemote] Old 2-3 day calls will be SKIPPED (only last 24h)');
        
        // Process all call logs from last 24 hours ONLY
        // OPTIMIZATION: Since calls are sorted newest first, we can break early
        int processedCount = 0;
        int uploadedCount = 0;
        int skippedOldCount = 0;
        
        for (final call in callLogList) {
          final ts = call.timestamp ?? 0;
          final number = call.number ?? '';
          
          // OPTIMIZATION: Early exit - as soon as we hit 24-hour threshold, stop
          // (calls are sorted newest first, so all remaining are older)
          if (ts < twentyFourHoursAgo) {
            skippedOldCount = callLogList.length - processedCount;
            print('⏭️ [CallLogRemote] Reached 24-hour threshold - stopping early');
            print('   Processed: $processedCount calls, Skipping: $skippedOldCount old calls');
            break;
          }
          
          // Skip if no number
          if (number.trim().isEmpty) continue;
          
          // Process call (already verified it's within 24 hours)
          print('🆕 [CallLogRemote] Processing call: ${call.name ?? 'Unknown'} ($number)');
          
          final callLogModel = CallLogModel.fromCallLogEntry(
            entry: call,
            childId: childId,
            parentId: parentId,
          );
          await _uploadCallLog(callLogModel);
          
          processedCount++;
          uploadedCount++;
        }
        
        // Set timestamp to current time (with 2s safety window) for future runs
        final safeTimestamp = now - 2000;
        await prefs.setInt(lastTsKey, safeTimestamp);
        
        print('✅ [CallLogRemote] First run complete:');
        print('   Processed: $processedCount calls (last 24h)');
        print('   Uploaded: $uploadedCount calls');
        print('   Skipped: $skippedOldCount old calls (2+ days)');
        print('ℹ️ [CallLogRemote] Next run will process calls newer than: ${DateTime.fromMillisecondsSinceEpoch(safeTimestamp)}');
        return;
      }

      print('⏰ [CallLogRemote] Last processed timestamp: $lastTimestamp');
      print('🕐 [CallLogRemote] Current time: ${DateTime.now().millisecondsSinceEpoch}');
      
      // Show each call log for debugging
      for (int i = 0; i < callLogList.length && i < 10; i++) {
        final call = callLogList[i];
        final name = call.name ?? 'Unknown';
        final number = call.number ?? 'Unknown';
        final type = call.callType?.toString() ?? 'Unknown';
        final callTime = DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0);
        final timeAgo = DateTime.now().difference(callTime).inMinutes;
        print('📞 [CallLogRemote] Call ${i+1}: $name ($number) - $type (${timeAgo}m ago)');
      }
      
      int newCallCount = 0;
      int uploadedCount = 0;
      int latestTimestamp = lastTimestamp;
      
      // Calculate 24 hours threshold ONCE (outside loop for performance)
      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;

      for (final call in callLogList) {
        final ts = call.timestamp ?? 0;
        final number = call.number ?? '';

        // OPTIMIZATION: Check 24 hours filter FIRST (skip old calls immediately, no processing)
        // This prevents unnecessary processing of very old calls
        if (ts < twentyFourHoursAgo) {
          // Silently skip - no need to log thousands of old calls
          continue;
        }
        
        // Skip already processed call logs (duplicate check)
        if (ts <= lastTimestamp) {
          // Silently skip - already processed in previous run
          continue;
        }

        if (number.trim().isEmpty) continue;

        newCallCount++;
        print('🆕 [CallLogRemote] NEW call found: ${call.name ?? 'Unknown'} ($number)');
        print('📅 [CallLogRemote] Call timestamp: $ts (last: $lastTimestamp)');

        // 📤 Upload to Firebase
        final callLogModel = CallLogModel.fromCallLogEntry(
          entry: call,
          childId: childId,
          parentId: parentId,
        );

        await _uploadCallLog(callLogModel);
        uploadedCount++;
        print('✅ [CallLogRemote] Call log uploaded to Firebase');

        if (ts > latestTimestamp) latestTimestamp = ts;
      }

      // 🕓 Update timestamp only if new calls processed

      // ⚠️ IMPORTANT: Subtract 2000ms safety window to prevent missing new calls
      // Some devices add call logs with future timestamps or 1-2 second delay
      if (newCallCount > 0) {
        // Prevent skip if call log timestamp mismatched (future timestamp issue)
        final safeTimestamp = latestTimestamp - 2000;
        await prefs.setInt(lastTsKey, safeTimestamp);
        
        final latestTime = DateTime.fromMillisecondsSinceEpoch(latestTimestamp);
        final safeTime = DateTime.fromMillisecondsSinceEpoch(safeTimestamp);
        
        print('✅ [CallLogRemote] Processed $newCallCount calls, uploaded $uploadedCount');
        print('⏰ [CallLogRemote] Updated last processed timestamp');
        print('   Latest call: ${latestTime.toIso8601String()}');
        print('   Safe timestamp: ${safeTime.toIso8601String()} (2s safety window)');
        print('ℹ️ [CallLogRemote] Next run will process calls after: ${safeTime.toIso8601String()}');
      } else {
        print('😴 [CallLogRemote] No new call logs found');
        print('ℹ️ [CallLogRemote] All calls are older than: ${DateTime.fromMillisecondsSinceEpoch(lastTimestamp)}');
        print('ℹ️ [CallLogRemote] Current time: ${DateTime.now()}');
        print('ℹ️ [CallLogRemote] Time difference: ${(DateTime.now().millisecondsSinceEpoch - lastTimestamp) / 1000}s');
      }

      print('✅ [CallLogRemote] Cycle complete | Checked: ${callLogList.length}, New: $newCallCount, Uploaded: $uploadedCount');
    } catch (e) {
      print('❌ [CallLogRemote] Error during monitoring: $e');
    }
  }

  /// 🧪 Process recent call logs immediately (for testing)
  Future<void> _processRecentCallLogs(String parentId, String childId) async {
    print('🧪 [CallLogRemote] Processing recent call logs for immediate upload...');
    
    int processedCount = 0;
    int uploadedCount = 0;
    
    // Process calls from last 24 hours ONLY (not old 2-3 day calls)
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
    
    print('📅 [CallLogRemote] Processing calls from last 24 hours only');
    print('📅 [CallLogRemote] Filter threshold: ${DateTime.fromMillisecondsSinceEpoch(twentyFourHoursAgo)}');
    
    try {
      final Iterable<CallLogEntry> callLogs = await CallLog.get();
      
      for (final call in callLogs) {
        final ts = call.timestamp ?? 0;
        final number = call.number ?? '';
        
        // Skip calls older than 24 hours
        if (ts < twentyFourHoursAgo || number.trim().isEmpty) continue;
        
        processedCount++;
        print('🆕 [CallLogRemote] Processing call: ${call.name ?? 'Unknown'} ($number)');
        
        // Upload to Firebase
        final callLogModel = CallLogModel.fromCallLogEntry(
          entry: call,
          childId: childId,
          parentId: parentId,
        );
        
        await _uploadCallLog(callLogModel);
        uploadedCount++;
      }
      
      // Update timestamp to current time (with 2s safety window)
      final prefs = await SharedPreferences.getInstance();
      final lastTsKey = 'last_call_log_timestamp_$childId';
      final safeTimestamp = DateTime.now().millisecondsSinceEpoch - 2000;
      await prefs.setInt(lastTsKey, safeTimestamp);
      
      print('✅ [CallLogRemote] Processed $processedCount calls, uploaded $uploadedCount');
      print('⏰ [CallLogRemote] Updated timestamp with 2s safety window');
    } catch (e) {
      print('❌ [CallLogRemote] Error processing recent calls: $e');
    }
  }


  /// 📤 Upload call log to Firebase
  Future<void> _uploadCallLog(CallLogModel callLog) async {
    try {
      print('');
      print('📞 ========== 📞 UPLOADING CALL LOG 📞 ==========');
      print('📤 [CallLogRemote] Uploading call log to Firebase...');
      print('📤 [CallLogRemote] Path: parents/${callLog.parentId}/children/${callLog.childId}/call_logs');
      print('📤 [CallLogRemote] Number: ${callLog.number}');
      print('📤 [CallLogRemote] Name: ${callLog.name ?? 'Unknown'}');
      print('📤 [CallLogRemote] Type: ${callLog.callTypeString}');
      print('📤 [CallLogRemote] Duration: ${callLog.duration} seconds');
      print('📤 [CallLogRemote] Date: ${callLog.dateTime}');
      
      final docRef = await firestore
          .collection('parents')
          .doc(callLog.parentId)
          .collection('children')
          .doc(callLog.childId)
          .collection('call_logs')
          .add(callLog.toMap());
      
      print('✅ [CallLogRemote] Call log uploaded successfully!');
      print('✅ [CallLogRemote] Document ID: ${docRef.id}');
      print('✅ [CallLogRemote] Parent side should now see this call');
      print('📞 ==============================================');
      print('');
    } catch (e) {
      print('❌ [CallLogRemote] Error uploading call log: $e');
      print('❌ [CallLogRemote] Stack trace: ${StackTrace.current}');
    }
  }

  /// 🔍 Fetch call logs for parent view
  /// Get call logs - ONLY last 24 hours (not old 2-3 day old calls)
  Future<List<CallLogModel>> getCallLogs({
    required String parentId,
    required String childId,
  }) async {
    try {
      print('📞 [CallLogRemote] Fetching call logs from Firebase (last 24 hours only)...');
      print('📞 [CallLogRemote] Path: parents/$parentId/children/$childId/call_logs');
      
      // Only fetch calls from last 24 hours
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      final twentyFourHoursAgoMs = twentyFourHoursAgo.millisecondsSinceEpoch;
      
      print('📅 [CallLogRemote] Fetching calls from: ${twentyFourHoursAgo.toIso8601String()} to now');
      print('📅 [CallLogRemote] Timestamp filter: $twentyFourHoursAgoMs (milliseconds)');
      
      final snapshot = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('call_logs')
          .where('dateTime', isGreaterThanOrEqualTo: twentyFourHoursAgoMs) // >= 24 hours ago (includes exactly 24h)
          .orderBy('dateTime', descending: true)
          .get();

      print('📞 [CallLogRemote] Firebase query returned ${snapshot.docs.length} documents (last 24h)');
      
      final callLogs = snapshot.docs.map((doc) {
        return CallLogModel.fromMap(doc.data());
      }).toList();
      
      print('✅ [CallLogRemote] Successfully loaded ${callLogs.length} call logs (last 24 hours)');
      return callLogs;
    } catch (e) {
      print('❌ [CallLogRemote] Error fetching call logs: $e');
      return [];
    }
  }

  /// Get real-time stream of call logs (last 24 hours only)
  /// New calls will automatically appear in the list
  Stream<List<CallLogModel>> getCallLogsStream({
    required String parentId,
    required String childId,
  }) {
    try {
      print('📞 [CallLogRemote] Setting up real-time stream for call logs (last 24 hours)...');
      
      // Only fetch calls from last 24 hours
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      final twentyFourHoursAgoMs = twentyFourHoursAgo.millisecondsSinceEpoch;
      
      print('📅 [CallLogRemote] Stream filter: calls after ${twentyFourHoursAgo.toIso8601String()}');
      
      // Use snapshots() for real-time updates
      // Note: Firebase requires composite index for where + orderBy
      // If error occurs, it will be caught and handled
      return firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('call_logs')
          .where('dateTime', isGreaterThanOrEqualTo: twentyFourHoursAgoMs) // >= 24 hours ago (includes exactly 24h)
          .orderBy('dateTime', descending: true)
          .snapshots()
          .map((snapshot) {
            print('🔄 [CallLogRemote] Stream snapshot received: ${snapshot.docs.length} documents');
            
            final callLogs = snapshot.docs.map((doc) {
              try {
                return CallLogModel.fromMap(doc.data());
              } catch (e) {
                print('⚠️ [CallLogRemote] Error parsing call log doc ${doc.id}: $e');
                return null;
              }
            }).whereType<CallLogModel>().toList();
            
            print('✅ [CallLogRemote] Stream update: ${callLogs.length} valid calls (last 24h)');
            return callLogs;
          })
          .handleError((error) {
            print('❌ [CallLogRemote] Stream error: $error');
            // If composite index error, try without orderBy as fallback
            if (error.toString().contains('index') || error.toString().contains('requires an index')) {
              print('⚠️ [CallLogRemote] Composite index required. Using fallback query...');
              return _getCallLogsStreamFallback(parentId, childId, twentyFourHoursAgoMs);
            }
            return <CallLogModel>[];
          });
    } catch (e) {
      print('❌ [CallLogRemote] Error setting up call logs stream: $e');
      return Stream.value([]);
    }
  }

  /// Fallback stream without orderBy (if composite index not available)
  Stream<List<CallLogModel>> _getCallLogsStreamFallback(
    String parentId,
    String childId,
    int twentyFourHoursAgoMs,
  ) {
    return firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('call_logs')
        .where('dateTime', isGreaterThanOrEqualTo: twentyFourHoursAgoMs) // >= 24 hours ago (consistent with main query)
        .snapshots()
        .map((snapshot) {
          final callLogs = snapshot.docs
              .map((doc) {
                try {
                  return CallLogModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<CallLogModel>()
              .toList();
          
          // Sort manually in memory (descending by dateTime)
          callLogs.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          
          print('✅ [CallLogRemote] Fallback stream: ${callLogs.length} calls (sorted in memory)');
          return callLogs;
        });
  }
}
