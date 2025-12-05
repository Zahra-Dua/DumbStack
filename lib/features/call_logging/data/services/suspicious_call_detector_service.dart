import 'dart:async';
import 'package:call_log/call_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/call_alert_model.dart';
import '../../../watch_list/data/services/watch_list_firebase_service.dart';
import '../../../notifications/data/services/notification_integration_service.dart';

class SuspiciousCallDetectorService {
  final FirebaseFirestore firestore;
  final String childId;
  final String parentId;
  final Duration lookbackWindow;
  final int repeatedThreshold;
  final int longCallThresholdSeconds;
  final int highVolumeThreshold;

  SuspiciousCallDetectorService({
    required this.firestore,
    required this.childId,
    required this.parentId,
    this.lookbackWindow = const Duration(hours: 24),
    this.repeatedThreshold = 3,
    this.longCallThresholdSeconds = 300, // 5 minutes
    this.highVolumeThreshold = 10,
  });

  /// Simple scan: Fetch last 24 hours call logs and apply rules
  /// No background listener - just scan when called
  Future<void> scanCallLogs() async {
    print('🔍 [CallDetector] ========== SCANNING CALL LOGS ==========');
    print('   Child ID: $childId');
    print('   Parent ID: $parentId');
    print('   Scanning last 24 hours of calls...');
    print('==================================================');
    
    await runDetection();
  }

  /// Ensure runtime permissions for call log & contacts are granted
  Future<bool> ensurePermissions() async {
    final callStatus = await Permission.phone.request();
    final contactsStatus = await Permission.contacts.request();

    if (callStatus.isGranted && contactsStatus.isGranted) {
      return true;
    }
    print('❌ [CallDetector] Permissions not granted');
    return false;
  }

  /// Normalize phone numbers to E.164-like simplified format
  /// PERFECT matching for call logs, contacts, and watchlist
  String normalizeNumber(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    // Remove all non-digits (keep only numbers)
    String s = raw.replaceAll(RegExp(r'[^0-9]'), '');

    // Handle Pakistani number formats
    // Case 1: Already has country code (92XXXXXXXXXX) -> +92XXXXXXXXXX
    if (s.startsWith('92') && s.length == 12) {
      s = '+$s';
    }
    // Case 2: Local format (0XXXXXXXXXX) -> +92XXXXXXXXXX
    else if (s.startsWith('0') && s.length == 11) {
      s = '+92${s.substring(1)}';
    }
    // Case 3: 10 digits (XXXXXXXXXX) -> +92XXXXXXXXXX
    else if (s.length == 10) {
      s = '+92$s';
    }
    // Case 4: Already has + prefix
    else if (s.startsWith('+')) {
      // Already normalized
    }
    // Case 5: If starts with 92 but no +, add it
    else if (s.startsWith('92') && s.length >= 12) {
      s = '+$s';
    }

    return s;
  }

  /// Load contacts and produce a set of normalized numbers
  Future<Set<String>> loadContactNumbersNormalized() async {
    final Set<String> out = {};
    try {
      // Check contacts permission
      final contactsStatus = await Permission.contacts.status;
      if (contactsStatus != PermissionStatus.granted) {
        print('⚠️ [CallDetector] Contacts permission not granted - requesting...');
        final requestResult = await Permission.contacts.request();
        if (requestResult != PermissionStatus.granted) {
          print('⚠️ [CallDetector] Contacts permission denied - will use call log name field only');
          return out;
        }
      }

      // Request permission from flutter_contacts
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) {
        print('⚠️ [CallDetector] FlutterContacts permission denied');
        return out;
      }

      // Load all contacts
      print('📇 [CallDetector] Loading contacts from device...');
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      print('📇 [CallDetector] Found ${contacts.length} contacts');

      // Extract and normalize all phone numbers
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = normalizeNumber(phone.number);
          if (normalized.isNotEmpty) {
            out.add(normalized);
          }
        }
      }

      print('✅ [CallDetector] Loaded ${out.length} normalized contact numbers');
      
      if (out.isEmpty) {
        print('ℹ️ [CallDetector] No contacts found - will rely on call log name field');
      }
    } catch (e) {
      print('⚠️ [CallDetector] Error loading contacts: $e');
      print('ℹ️ [CallDetector] Will use call log name field as fallback');
    }
    return out;
  }

  // Removed fetchCallsAfter - now using simple approach in runDetection()

  /// Main detection function - Simple approach: Fetch last 24 hours and apply rules
  /// No complex timestamp tracking - just scan last 24 hours every time
  Future<void> runDetection() async {
    print('🔍 [CallDetector] ========== RUN DETECTION STARTED ==========');
    print('   Timestamp: ${DateTime.now().toIso8601String()}');
    
    // Check permissions
    final okPerm = await ensurePermissions();
    if (!okPerm) {
      print('❌ [CallDetector] Permissions not granted - cannot analyze call logs.');
      print('   ⚠️ Please grant CALL_LOG and CONTACTS permissions');
      return;
    }
    print('✅ [CallDetector] Permissions granted');

    // Simple approach: Always fetch last 24 hours of calls
    final now = DateTime.now();
    final fromTime = now.subtract(lookbackWindow);
    final fromTimestamp = fromTime.millisecondsSinceEpoch;

    print('📅 [CallDetector] Fetching calls from last 24 hours');
    print('   From: ${fromTime.toIso8601String()}');
    print('   To: ${now.toIso8601String()}');

    // Fetch calls and filter last 24 hours (optimized - early exit)
    try {
      final allCalls = await CallLog.get();
      print('📞 [CallDetector] Total calls in device: ${allCalls.length}');
      
      // OPTIMIZATION: Sort by timestamp (newest first) and use takeWhile
      // This way, as soon as we hit a call older than 24 hours, we stop processing
      final sortedCalls = allCalls.toList()
        ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
      
      // Use takeWhile to stop as soon as we hit 24-hour threshold
      // This prevents processing thousands of old calls
      final recentCalls = <CallLogEntry>[];
      for (final call in sortedCalls) {
        final ts = call.timestamp ?? 0;
        if (ts >= fromTimestamp) {
          recentCalls.add(call);
        } else {
          // As soon as we hit a call older than 24 hours, stop (calls are sorted newest first)
          print('⏭️ [CallDetector] Reached 24-hour threshold - stopping early');
          print('   Processed ${recentCalls.length} recent calls, skipped ${sortedCalls.length - recentCalls.length} old calls');
          break;
        }
      }
      
      print('📞 [CallDetector] Calls from last 24 hours: ${recentCalls.length}');
      
      if (recentCalls.isEmpty) {
        print('😴 [CallDetector] No calls found in last 24 hours');
        return;
      }
      
      // Log sample calls
      for (int i = 0; i < recentCalls.length && i < 5; i++) {
        final call = recentCalls[i];
        final callTime = call.timestamp != null 
            ? DateTime.fromMillisecondsSinceEpoch(call.timestamp!)
            : DateTime.now();
        print('   📞 Call ${i+1}: ${call.name ?? "Unknown"} (${call.number ?? "no number"}) - ${_getCallTypeString(call.callType)} at ${callTime.toIso8601String()}');
      }

      // Analyze all recent calls and apply rules
      print('🔍 [CallDetector] Starting analysis of ${recentCalls.length} calls...');
      await analyzeNewCalls(recentCalls);
      print('✅ [CallDetector] Analysis completed');
      
    } catch (e) {
      print('❌ [CallDetector] Error fetching call logs: $e');
    }
  }

  /// Analyze only NEW calls and create alerts
  Future<void> analyzeNewCalls(List<CallLogEntry> calls) async {
    print('🔍 [CallDetector] ========== ANALYZE NEW CALLS ==========');
    print('   Total calls to analyze: ${calls.length}');
    
    if (calls.isEmpty) {
      print('ℹ️ [CallDetector] No calls to analyze - exiting');
      return;
    }
    
    final contactNumbers = await loadContactNumbersNormalized();
    print('📇 [CallDetector] Loaded ${contactNumbers.length} contact numbers for comparison');
    
    final watchListService = WatchListFirebaseService();

    // Build frequency map (normalized number -> entries)
    final Map<String, List<CallLogEntry>> numberMap = {};
    for (final call in calls) {
      final norm = normalizeNumber(call.number);
      if (norm.isEmpty) continue;
      numberMap.putIfAbsent(norm, () => []).add(call);
    }

    // Get watchlist numbers
    List<String> watchlistNumbers = [];
    try {
      final watchList = await watchListService.getWatchListContacts(
        parentId: parentId,
        childId: childId,
      );
      watchlistNumbers = watchList
          .map((contact) => normalizeNumber(contact.phoneNumber))
          .toList();
    } catch (e) {
      print('⚠️ [CallDetector] Error loading watchlist: $e');
    }

    // Track processed alerts to avoid duplicates
    final Set<String> processedAlerts = {};

    // Iterate numbers and apply rules
    for (final kv in numberMap.entries) {
      final number = kv.key;
      final callsForNumber = kv.value;
      final int count = callsForNumber.length;

      // Check if number is known (ONLY check contacts - call log name is unreliable)
      // Some devices fill call log names with weird values even for unknown numbers
      // So we ONLY trust the contacts list for "known" detection
      final bool inContacts = contactNumbers.contains(number);
      final bool known = inContacts; // ONLY use contacts - ignore call log name
      
      // Log for debugging (for all numbers to track detection)
      final sampleCall = callsForNumber.first;
      if (!known) {
        print('🔍 [CallDetector] ⚠️ UNKNOWN NUMBER DETECTED: $number');
        print('   Name in call log: ${sampleCall.name ?? "null"}');
        print('   In contacts: $inContacts');
        print('   Call count: ${callsForNumber.length}');
      } else {
        print('✅ [CallDetector] Known number: $number (in contacts)');
      }

      // ⚠️ RULE 1: Watchlist -> MUST CHECK FIRST (before known check)
      // Watchlist takes priority - even if number is in contacts, flag it
      if (watchlistNumbers.contains(number)) {
        // Get the most recent call
        final mostRecentCall = callsForNumber.reduce((a, b) => 
            (a.timestamp ?? 0) > (b.timestamp ?? 0) ? a : b);
        
        final alertKey = 'WATCHLIST_${number}_${mostRecentCall.timestamp}';
        if (!processedAlerts.contains(alertKey)) {
          final callType = _getCallTypeString(mostRecentCall.callType);
          final duration = mostRecentCall.duration ?? 0;
          final durationStr = duration > 0 
              ? _formatDuration(duration)
              : 'Missed call';
          
          await createAlert(
            number,
            reason: 'Watchlist contact: $callType call ($durationStr)',
            rule: 'WATCHLIST',
            callExample: mostRecentCall,
            contactName: mostRecentCall.name,
            duration: duration > 0 ? duration : null,
          );
          processedAlerts.add(alertKey);
          print('🚨 [CallDetector] Flagged watchlist call: $number ($callType)');
        }
        continue; // Skip other rules if watchlist already flagged
      }

      // Rule 1.5: ANY unknown call (missed, incoming, outgoing) - immediate flag
      // This catches ALL unknown numbers regardless of call type or duration
      if (!known) {
        print('🔍 [CallDetector] ⚠️ UNKNOWN NUMBER DETECTED: $number');
        print('   Total calls for this number: ${callsForNumber.length}');
        print('   Processing ALL calls for this unknown number...');
        
        // Process ALL calls for this unknown number (not just most recent)
        for (final call in callsForNumber) {
          final callType = _getCallTypeString(call.callType);
          final duration = call.duration ?? 0;
          final timestamp = call.timestamp ?? 0;
          
          // Create unique alert key per call (using timestamp to allow multiple alerts for same number)
          final alertKey = 'UNKNOWN_CALL_${number}_$timestamp';
          
          if (!processedAlerts.contains(alertKey)) {
            String reason;
            if (duration > 0) {
              final durationStr = _formatDuration(duration);
              reason = 'Unknown number: $callType call ($durationStr)';
            } else {
              reason = 'Unknown number: $callType call (missed)';
            }
            
            print('🚨 [CallDetector] ========== CREATING UNKNOWN CALL ALERT ==========');
            print('   Number: $number');
            print('   Call Type: $callType');
            print('   Duration: ${duration > 0 ? _formatDuration(duration) : "missed"}');
            print('   Timestamp: $timestamp');
            print('   Reason: $reason');
            print('   About to call createAlert()...');
            
            await createAlert(
              number,
              reason: reason,
              rule: 'UNKNOWN_CALL',
              callExample: call,
              duration: duration > 0 ? duration : null,
            );
            processedAlerts.add(alertKey);
            print('✅ [CallDetector] Alert created and saved for: $number');
            print('==================================================');
          } else {
            print('⏭️ [CallDetector] Alert already processed for: $number (timestamp: $timestamp)');
          }
        }
      } else {
        print('✅ [CallDetector] Known number: $number (in contacts) - skipping UNKNOWN_CALL rule');
      }

      // Rule 2: Repeated unknown calls
      if (!known && count >= repeatedThreshold) {
        final alertKey = 'REPEATED_UNKNOWN_$number';
        if (!processedAlerts.contains(alertKey)) {
          await createAlert(
            number,
            reason:
                'Repeated unknown number calls ($count times in last ${lookbackWindow.inHours}h)',
            rule: 'REPEATED_UNKNOWN',
            callExample: callsForNumber.last,
            countLast24h: count,
          );
          processedAlerts.add(alertKey);
        }
      }

      // Rule 3: Long duration unknown number call
      final CallLogEntry longest = callsForNumber.reduce((a, b) {
        final da = (a.duration ?? 0);
        final db = (b.duration ?? 0);
        return da >= db ? a : b;
      });

      final longestDuration = longest.duration ?? 0;
      if (!known &&
          longestDuration >= longCallThresholdSeconds &&
          longestDuration > 0) {
        final alertKey = 'LONG_UNKNOWN_CALL_$number';
        if (!processedAlerts.contains(alertKey)) {
          await createAlert(
            number,
            reason: 'Long duration call with unknown number',
            rule: 'LONG_UNKNOWN_CALL',
            callExample: longest,
            duration: longestDuration,
          );
          processedAlerts.add(alertKey);
        }
      }

      // Rule 4: Odd hours call (late night)
      for (final c in callsForNumber) {
        if (c.timestamp == null) continue;
        final dt = DateTime.fromMillisecondsSinceEpoch(c.timestamp!);
        if (_isLateNight(dt)) {
          final alertKey = 'ODD_HOUR_${number}_${c.timestamp}';
          if (!processedAlerts.contains(alertKey)) {
            await createAlert(
              number,
              reason: 'Call at odd hours (${dt.hour}:${dt.minute.toString().padLeft(2, '0')})',
              rule: 'ODD_HOUR',
              callExample: c,
              contactName: c.name,
            );
            processedAlerts.add(alertKey);
          }
          break; // Only one alert per number for odd hours
        }
      }
    }

    // Rule 5: High volume overall (only once per run)
    final totalCalls = calls.length;
    if (totalCalls >= highVolumeThreshold) {
      final alertKey = 'HIGH_VOLUME_${DateTime.now().day}';
      if (!processedAlerts.contains(alertKey)) {
        await createAlert(
          '*',
          reason: 'High call volume detected in last ${lookbackWindow.inHours}h',
          rule: 'HIGH_VOLUME',
          callExample: calls.first,
          countLast24h: totalCalls,
        );
        processedAlerts.add(alertKey);
      }
    }
  }

  bool _isLateNight(DateTime dt) {
    final hour = dt.hour;
    return (hour >= 23 || hour < 6);
  }

  /// Format duration in seconds to readable string (e.g., "2 m 30 s" or "45 s")
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 s';
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes m $remainingSeconds s';
    }
    return '$remainingSeconds s';
  }

  /// Get call type as string (incoming, outgoing, missed)
  String _getCallTypeString(CallType? callType) {
    if (callType == null) return 'unknown';
    switch (callType) {
      case CallType.incoming:
        return 'incoming';
      case CallType.outgoing:
        return 'outgoing';
      case CallType.missed:
        return 'missed';
      default:
        return 'unknown';
    }
  }

  /// Create alert document in Firestore
  Future<void> createAlert(
    String number, {
    required String reason,
    required String rule,
    CallLogEntry? callExample,
    int? duration,
    int? countLast24h,
    String? contactName,
  }) async {
    print('🚨 [CallDetector] ========== CREATE ALERT CALLED ==========');
    print('   Number: $number');
    print('   Rule: $rule');
    print('   Reason: $reason');
    print('   Child ID: $childId');
    print('   Parent ID: $parentId');
    
    try {
      // For UNKNOWN_CALL and WATCHLIST rules, allow multiple alerts (one per call)
      // For other rules, check for duplicates in last 1 hour
      if (rule != 'UNKNOWN_CALL' && rule != 'WATCHLIST') {
        final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
        final recentAlerts = await firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('flagged_calls')
            .where('number', isEqualTo: number)
            .where('rule', isEqualTo: rule)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
            .limit(1)
            .get();

        if (recentAlerts.docs.isNotEmpty) {
          print('⏭️ [CallDetector] Duplicate alert skipped for $number (rule: $rule)');
          return;
        }
      } else {
        // For UNKNOWN_CALL and WATCHLIST, check if exact same call (same timestamp) was already flagged
        if (callExample?.timestamp != null) {
          final callTimestamp = DateTime.fromMillisecondsSinceEpoch(callExample!.timestamp!);
          print('🔍 [CallDetector] Checking for duplicate alert: $number, rule: $rule, timestamp: ${callTimestamp.toIso8601String()}');
          
          // Check if this exact call was already flagged (within last 5 minutes to avoid duplicates)
          final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
          final recentAlerts = await firestore
              .collection('parents')
              .doc(parentId)
              .collection('children')
              .doc(childId)
              .collection('flagged_calls')
              .where('number', isEqualTo: number)
              .where('rule', isEqualTo: rule)
              .where('createdAt', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
              .limit(10)
              .get();

          // Check if any alert has the same timestamp (exact same call)
          bool isDuplicate = false;
          for (final doc in recentAlerts.docs) {
            final data = doc.data();
            final alertTimestamp = data['timestamp'];
            if (alertTimestamp != null) {
              DateTime alertTime;
              if (alertTimestamp is Timestamp) {
                alertTime = alertTimestamp.toDate();
              } else if (alertTimestamp is String) {
                alertTime = DateTime.parse(alertTimestamp);
              } else {
                alertTime = DateTime.fromMillisecondsSinceEpoch(alertTimestamp);
              }
              
              // Check if timestamps match (within 1 second tolerance)
              final timeDiff = (callTimestamp.millisecondsSinceEpoch - alertTime.millisecondsSinceEpoch).abs();
              if (timeDiff < 1000) {
                isDuplicate = true;
                print('⏭️ [CallDetector] Same call already flagged (timestamp diff: ${timeDiff}ms)');
                break;
              }
            }
          }

          if (isDuplicate) {
            print('⏭️ [CallDetector] Duplicate alert skipped for $number (rule: $rule)');
            return;
          }
          
          print('✅ [CallDetector] No duplicate found - proceeding to create alert');
        }
      }

      final alertId = const Uuid().v4();
      final now = DateTime.now();
      final callTs = callExample != null && callExample.timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(callExample.timestamp!)
          : now;

      final alert = CallAlertModel(
        alertId: alertId,
        childId: childId,
        number: number,
        reason: reason,
        duration: duration ?? (callExample?.duration ?? 0),
        timestamp: callTs,
        rule: rule,
        callType: callExample?.callType?.toString().split('.').last ?? 'UNKNOWN',
        countLast24h: countLast24h ?? 0,
        createdAt: now,
        contactName: contactName ?? callExample?.name,
      );

      final alertRef = firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_calls')
          .doc(alertId);
      
      print('📤 [CallDetector] Saving alert to Firebase: $alertId');
      print('   Path: parents/$parentId/children/$childId/flagged_calls/$alertId');
      print('   Number: $number');
      print('   Rule: $rule');
      print('   Reason: $reason');
      
      await alertRef.set(alert.toMap());
      
      // Verify the alert was saved
      final verifyDoc = await alertRef.get();
      if (verifyDoc.exists) {
        print('✅ [CallDetector] Alert created and verified in Firebase: $reason');
      } else {
        print('❌ [CallDetector] ERROR: Alert was not saved to Firebase!');
      }

      // Send notification to parent
      try {
        final notificationService = NotificationIntegrationService();
        await notificationService.onSuspiciousCallDetected(
          parentId: parentId,
          childId: childId,
          callerNumber: number,
          callerName: contactName ?? callExample?.name ?? number,
          callType: alert.callType.toLowerCase(),
          duration: alert.duration,
          transcription: null,
        );
        print('✅ [CallDetector] Notification sent to parent');
      } catch (e) {
        print('⚠️ [CallDetector] Error sending notification: $e');
      }
    } catch (e) {
      print('❌ [CallDetector] Error creating alert: $e');
    }
  }

  /// Reset timestamp for testing
  Future<void> resetTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTsKey = 'last_suspicious_call_timestamp_$childId';
    await prefs.setInt(lastTsKey, 0);
    print('🔄 [CallDetector] Timestamp reset to 0');
  }
}

