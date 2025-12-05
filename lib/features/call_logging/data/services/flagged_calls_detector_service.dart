import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/call_log_model.dart';
import '../../../watch_list/data/services/watch_list_firebase_service.dart';
import '../../../notifications/data/services/notification_integration_service.dart';

/// Service to detect suspicious calls based on 3 rules:
/// 1. Unknown number (not in contacts)
/// 2. Odd hours (11 PM - 6 AM)
/// 3. Watchlist number
class FlaggedCallsDetectorService {
  final FirebaseFirestore firestore;
  final String parentId;
  final String childId;

  FlaggedCallsDetectorService({
    required this.firestore,
    required this.parentId,
    required this.childId,
  });

  /// Check if call is suspicious based on 3 rules
  /// Rules priority:
  /// 1. Watchlist → Always suspicious (highest priority)
  /// 2. Invalid format (alphabets) → Suspicious
  /// 3. Unknown number (not in contacts) → Suspicious
  /// 4. Odd hours (11 PM - 6 AM) → Suspicious
  /// 
  /// If number is in contacts → NOT suspicious (unless watchlist)
  bool isSuspiciousCall({
    required String number,
    required DateTime timestamp,
    required Set<String> approvedContacts,
    required Set<String> watchlist,
  }) {
    final normalizedNumber = _normalizeNumber(number);
    
    // Rule 1: Watchlist (Always suspicious - highest priority)
    // Even if number is in contacts, watchlist takes priority
    if (watchlist.contains(normalizedNumber)) {
      print('🚨 [FlaggedCallsDetector] Watchlist match: $number');
      return true;
    }

    // Rule 2: Invalid number format (contains alphabets)
    if (_hasAlphabets(number)) {
      print('🚨 [FlaggedCallsDetector] Invalid format (alphabets): $number');
      return true;
    }
    
    // Rule 3: Check if number is in contacts
    // If in contacts → NOT suspicious (safe contact)
    if (approvedContacts.contains(normalizedNumber)) {
      print('✅ [FlaggedCallsDetector] Known contact: $number - NOT suspicious');
      return false; // Known contact, not suspicious
    }
    
    // Rule 4: Unknown number (not in contacts) → Suspicious
    print('🚨 [FlaggedCallsDetector] Unknown number (not in contacts): $number');
    
    // Rule 5: Odd hours (11 PM - 6 AM) → Additional flag
    final hour = timestamp.hour;
    if (hour >= 23 || hour < 6) {
      print('🚨 [FlaggedCallsDetector] Odd hours call: $number at ${hour}:${timestamp.minute}');
      return true;
    }

    // Unknown number (not in contacts) = Suspicious
    return true;
  }

  /// Normalize phone number for comparison
  String _normalizeNumber(String number) {
    // Remove spaces, dashes, parentheses, plus signs
    String normalized = number.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Handle Pakistani numbers (add +92 if starts with 0)
    if (normalized.startsWith('0') && normalized.length == 11) {
      normalized = '+92${normalized.substring(1)}';
    } else if (normalized.startsWith('92') && normalized.length == 12) {
      normalized = '+$normalized';
    }
    
    return normalized;
  }

  /// Check if number contains alphabets (invalid format)
  bool _hasAlphabets(String number) {
    return RegExp(r'[a-zA-Z]').hasMatch(number);
  }

  /// Load approved contacts from Firebase OR device contacts
  /// Priority: Firebase approved_contacts → Device contacts (fallback)
  Future<Set<String>> loadApprovedContacts() async {
    try {
      // First try: Load from Firebase (if parent has approved specific contacts)
      final snapshot = await firestore
          .collection('approved_contacts')
          .doc(childId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        final numbers = snapshot.data()!['numbers'] as List<dynamic>? ?? [];
        if (numbers.isNotEmpty) {
          final firebaseContacts = numbers.map((n) => _normalizeNumber(n.toString())).toSet();
          print('✅ [FlaggedCallsDetector] Loaded ${firebaseContacts.length} approved contacts from Firebase');
          return firebaseContacts;
        }
      }
      
      // Fallback: Load from device contacts (all saved contacts)
      print('ℹ️ [FlaggedCallsDetector] No Firebase approved contacts, loading device contacts...');
      return await _loadDeviceContacts();
    } catch (e) {
      print('⚠️ [FlaggedCallsDetector] Error loading approved contacts: $e');
      // Fallback to device contacts
      return await _loadDeviceContacts();
    }
  }

  /// Load device contacts as approved contacts (fallback)
  /// This loads ALL saved contacts from device
  Future<Set<String>> _loadDeviceContacts() async {
    try {
      // Request contacts permission
      final permission = await Permission.contacts.status;
      if (!permission.isGranted) {
        print('🔐 [FlaggedCallsDetector] Requesting contacts permission...');
        final requestResult = await Permission.contacts.request();
        if (!requestResult.isGranted) {
          print('⚠️ [FlaggedCallsDetector] Contacts permission denied');
          return <String>{};
        }
      }
      
      print('📇 [FlaggedCallsDetector] Loading device contacts...');
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final numbers = <String>{};
      
      for (final contact in contacts) {
        if (contact.phones.isNotEmpty) {
          for (final phone in contact.phones) {
            if (phone.number.isNotEmpty) {
              final normalized = _normalizeNumber(phone.number);
              if (normalized.isNotEmpty) {
                numbers.add(normalized);
              }
            }
          }
        }
      }
      
      print('✅ [FlaggedCallsDetector] Loaded ${numbers.length} contacts from device');
      if (numbers.isNotEmpty) {
        print('   Sample contacts: ${numbers.take(3).join(', ')}...');
      }
      return numbers;
    } catch (e) {
      print('❌ [FlaggedCallsDetector] Error loading device contacts: $e');
      return <String>{};
    }
  }

  /// Load watchlist numbers
  Future<Set<String>> loadWatchlist() async {
    try {
      final watchListService = WatchListFirebaseService();
      final watchList = await watchListService.getWatchListContacts(
        parentId: parentId,
        childId: childId,
      );
      
      return watchList
          .map((contact) => _normalizeNumber(contact.phoneNumber))
          .toSet();
    } catch (e) {
      print('⚠️ [FlaggedCallsDetector] Error loading watchlist: $e');
      return <String>{};
    }
  }

  /// Check and flag calls from call history
  Future<void> checkAndFlagCalls(List<CallLogModel> callLogs) async {
    try {
      print('🔍 [FlaggedCallsDetector] Checking ${callLogs.length} calls for suspicious activity...');
      
      // Load approved contacts and watchlist
      final approvedContacts = await loadApprovedContacts();
      final watchlist = await loadWatchlist();
      
      print('📇 [FlaggedCallsDetector] Loaded ${approvedContacts.length} approved contacts');
      print('👁️ [FlaggedCallsDetector] Loaded ${watchlist.length} watchlist numbers');
      
      int flaggedCount = 0;
      
      for (final call in callLogs) {
        final isSuspicious = isSuspiciousCall(
          number: call.number,
          timestamp: call.dateTime,
          approvedContacts: approvedContacts,
          watchlist: watchlist,
        );
        
        if (isSuspicious) {
          // Save to flagged_calls collection
          await _saveFlaggedCall(call);
          flaggedCount++;
          
          // Send notification to parent
          await _sendNotification(call);
        }
      }
      
      print('✅ [FlaggedCallsDetector] Flagged $flaggedCount calls out of ${callLogs.length}');
    } catch (e) {
      print('❌ [FlaggedCallsDetector] Error checking calls: $e');
    }
  }

  /// Save flagged call to Firebase
  Future<void> _saveFlaggedCall(CallLogModel call) async {
    try {
      // Check if already flagged (avoid duplicates)
      final existing = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_calls')
          .where('id', isEqualTo: call.id)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        print('⏭️ [FlaggedCallsDetector] Call already flagged: ${call.number}');
        return;
      }
      
      // Determine reason (check in same order as rules)
      final watchlist = await loadWatchlist();
      final approvedContacts = await loadApprovedContacts();
      final normalizedNumber = _normalizeNumber(call.number);
      
      String reason = '';
      final reasons = <String>[];
      
      // Rule 1: Watchlist
      if (watchlist.contains(normalizedNumber)) {
        reasons.add('Watchlist number');
      }
      
      // Rule 2: Invalid format
      if (_hasAlphabets(call.number)) {
        reasons.add('Invalid format (contains alphabets)');
      }
      
      // Rule 3: Unknown number (not in contacts)
      if (!approvedContacts.contains(normalizedNumber)) {
        reasons.add('Unknown number (not in contacts)');
      }
      
      // Rule 4: Odd hours
      final hour = call.dateTime.hour;
      if (hour >= 23 || hour < 6) {
        reasons.add('Odd hours (${call.dateTime.hour}:${call.dateTime.minute.toString().padLeft(2, '0')})');
      }
      
      // Combine all reasons
      reason = reasons.isNotEmpty ? reasons.join(', ') : 'Suspicious call detected';
      
      // Save flagged call
      await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_calls')
          .add({
        'id': call.id,
        'name': call.name,
        'number': call.number,
        'simDisplayName': call.simDisplayName,
        'duration': call.duration,
        'dateTime': call.dateTime.millisecondsSinceEpoch,
        'type': call.type.toString(),
        'childId': childId,
        'parentId': parentId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ [FlaggedCallsDetector] Flagged call saved: ${call.number} - $reason');
    } catch (e) {
      print('❌ [FlaggedCallsDetector] Error saving flagged call: $e');
    }
  }

  /// Send notification to parent
  Future<void> _sendNotification(CallLogModel call) async {
    try {
      final notificationService = NotificationIntegrationService();
      
      await notificationService.onSuspiciousCallDetected(
        parentId: parentId,
        childId: childId,
        callerNumber: call.number,
        callerName: call.name ?? call.number,
        callType: call.callTypeString.toLowerCase(),
        duration: call.duration,
        transcription: null,
      );
      
      print('✅ [FlaggedCallsDetector] Notification sent to parent');
    } catch (e) {
      print('⚠️ [FlaggedCallsDetector] Error sending notification: $e');
    }
  }
}

