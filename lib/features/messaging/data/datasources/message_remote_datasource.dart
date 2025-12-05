import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';
import '../../../notifications/data/services/notification_integration_service.dart';
import '../../../watch_list/data/services/watch_list_firebase_service.dart';

class MessageRemoteDataSourceImpl {
  final FirebaseFirestore firestore;
  Timer? _monitorTimer;
  bool _isRunning = false;

  MessageRemoteDataSourceImpl({required this.firestore});

  /// 🔁 Start background monitoring every 5 seconds
  void startContinuousMonitoring({
    required String parentId,
    required String childId,
  }) {
    if (_isRunning) {
      print('⚙️ [Monitor] Already running, skipping duplicate start');
      return;
    }

    print('🚀 [Monitor] Starting background message monitoring (every 5s)...');
    _isRunning = true;

    // Run immediately once, then every 5 seconds
    monitorChildMessages(parentId: parentId, childId: childId);
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      monitorChildMessages(parentId: parentId, childId: childId);
    });
  }

  /// 🛑 Stop background monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _isRunning = false;
    print('🛑 [Monitor] Message monitoring stopped.');
  }

  /// 🔄 Reset message timestamp for testing
  Future<void> resetMessageTimestamp(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTsKey = 'last_message_timestamp_$childId';
    await prefs.setInt(lastTsKey, 0); // Set to 0 instead of removing
    print('🔄 [MessageRemote] Message timestamp reset to 0 for child: $childId');
  }
  
  /// 🧹 Force reset and process all recent messages
  Future<void> forceResetAndProcess(String parentId, String childId) async {
    print('🔄 [MessageRemote] Force resetting and processing all recent messages...');
    
    // Reset timestamp to 0 to force reprocessing
    final prefs = await SharedPreferences.getInstance();
    final lastTsKey = 'last_message_timestamp_$childId';
    await prefs.setInt(lastTsKey, 0);
    
    // Process all messages from last 1 day
    await monitorChildMessages(parentId: parentId, childId: childId);
    
    print('✅ [MessageRemote] Force reset and process completed');
  }

  /// 🧪 Process recent messages immediately (for testing)
  Future<void> _processRecentMessages(String parentId, String childId, List<SmsMessage> messages) async {
    print('🧪 [MessageRemote] Processing recent messages for immediate analysis...');
    
    int processedCount = 0;
    int flaggedCount = 0;
    
    // Process messages from last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    
    for (final msg in messages) {
      final ts = msg.date?.millisecondsSinceEpoch ?? 0;
      final body = msg.body ?? '';
      
      if (ts < sevenDaysAgo || body.trim().isEmpty) continue;
      
      processedCount++;
      print('🆕 [MessageRemote] Processing message: "${body.length > 40 ? "${body.substring(0, 40)}..." : body}"');
      
      // Analyze via Flask
      final flagged = await _analyzeAndUpload(
        parentId: parentId,
        childId: childId,
        text: body,
        timestamp: ts,
        sender: msg.address ?? 'unknown',
      );
      
      if (flagged) flaggedCount++;
    }
    
    // Update timestamp to current time
    final prefs = await SharedPreferences.getInstance();
    final lastTsKey = 'last_message_timestamp_$childId';
    await prefs.setInt(lastTsKey, DateTime.now().millisecondsSinceEpoch);
    
    print('✅ [MessageRemote] Processed $processedCount messages, flagged $flaggedCount');
  }

  /// 📡 Main monitor called every 5 seconds
  Future<void> monitorChildMessages({
    required String parentId,
    required String childId,
  }) async {
    print('\n📡 [MessageRemote] Checking new messages for child: $childId');

    try {
      // Check SMS permission first
      final smsPermission = await Permission.sms.status;
      print('🔐 [MessageRemote] SMS Permission Status: $smsPermission');
      
      if (smsPermission != PermissionStatus.granted) {
        print('❌ [MessageRemote] SMS permission not granted - requesting...');
        final result = await Permission.sms.request();
        print('🔐 [MessageRemote] SMS Permission Request Result: $result');
        if (result != PermissionStatus.granted) {
          print('❌ [MessageRemote] SMS permission denied - cannot access messages');
          return;
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final lastTsKey = 'last_message_timestamp_$childId';
      int lastTimestamp = prefs.getInt(lastTsKey) ?? 0;

      // ✅ Fetch SMS messages first
      final SmsQuery query = SmsQuery();
      final List<SmsMessage> allMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50,
        sort: true,
      );
      
      // OPTIMIZATION: Sort by timestamp (newest first) for early exit
      final messages = allMessages.toList()
        ..sort((a, b) {
          final tsA = a.date?.millisecondsSinceEpoch ?? 0;
          final tsB = b.date?.millisecondsSinceEpoch ?? 0;
          return tsB.compareTo(tsA); // Newest first
        });
      
      print('📱 [MessageRemote] SMS Query Result: Found ${messages.length} messages (sorted newest first)');
      if (messages.isNotEmpty) {
        print('📱 [MessageRemote] First message: ${messages.first.body} from ${messages.first.address}');
        print('📱 [MessageRemote] Last message: ${messages.last.body} from ${messages.last.address}');
      } else {
        print('⚠️ [MessageRemote] No SMS messages found - check permissions!');
      }

      // Check if timestamp is corrupted (too large or in the future)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      // Check for timestamps that are way too large or in the future
      if (lastTimestamp > currentTime || lastTimestamp > 2000000000000 || lastTimestamp > 1000000000000 || lastTimestamp > 200000000000) { // Check for unrealistic timestamps
        print('⚠️ [MessageRemote] Corrupted timestamp detected: $lastTimestamp > $currentTime');
        print('🔄 [MessageRemote] Resetting timestamp...');
        lastTimestamp = 0; // Reset to force first-time setup
        await prefs.setInt(lastTsKey, 0); // Save the reset
        print('ℹ️ [MessageRemote] Timestamp reset to 0 - will initialize on next run');
        
        // Force immediate processing of recent messages
        print('🧪 [MessageRemote] Processing recent messages immediately...');
        await _processRecentMessages(parentId, childId, messages);
        return;
      }
      
      // Additional check for future timestamps (like 1758955140803 which is October 2025)
      final oneYearFromNow = DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch;
      if (lastTimestamp > oneYearFromNow) {
        print('⚠️ [MessageRemote] Future timestamp detected: $lastTimestamp > $oneYearFromNow');
        print('🔄 [MessageRemote] Resetting timestamp...');
        lastTimestamp = 0;
        await prefs.setInt(lastTsKey, 0);
        print('ℹ️ [MessageRemote] Timestamp reset to 0 - will initialize on next run');
        
        // Force immediate processing of recent messages
        print('🧪 [MessageRemote] Processing recent messages immediately...');
        await _processRecentMessages(parentId, childId, messages);
        return;
      }

      // 🕐 First-time setup - Process ONLY last 24 hours of messages (NOT old messages)
      if (lastTimestamp == 0) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
        
        print('🕐 [MessageRemote] First run detected → Processing ONLY last 24 hours of messages');
        print('📅 [MessageRemote] Processing messages from: ${DateTime.fromMillisecondsSinceEpoch(twentyFourHoursAgo)}');
        print('📅 [MessageRemote] Processing messages until: ${DateTime.fromMillisecondsSinceEpoch(now)}');
        print('⚠️ [MessageRemote] Old messages will be SKIPPED (only last 24h)');
        
        // Process all messages from last 24 hours ONLY
        // OPTIMIZATION: Since messages are sorted newest first, we can break early
        int processedCount = 0;
        int flaggedCount = 0;
        int skippedOldCount = 0;
        
        for (final msg in messages) {
          final ts = msg.date?.millisecondsSinceEpoch ?? 0;
          final body = msg.body ?? '';
          
          // OPTIMIZATION: Early exit - as soon as we hit 24-hour threshold, stop
          // (messages are sorted newest first, so all remaining are older)
          if (ts < twentyFourHoursAgo) {
            skippedOldCount = messages.length - processedCount;
            print('⏭️ [MessageRemote] Reached 24-hour threshold - stopping early');
            print('   Processed: $processedCount messages, Skipping: $skippedOldCount old messages');
            break;
          }
          
          // Skip if no body
          if (body.trim().isEmpty) continue;
          
          // Process message (already verified it's within 24 hours)
          final sender = msg.address ?? 'unknown';
          print('🆕 [MessageRemote] Processing message: "${body.length > 40 ? "${body.substring(0, 40)}..." : body}"');
          
          final flagged = await _analyzeAndUpload(
            parentId: parentId,
            childId: childId,
            text: body,
            timestamp: ts,
            sender: sender,
          );
          
          processedCount++;
          if (flagged) flaggedCount++;
        }
        
        // Set timestamp to current time (with 2s safety window) for future runs
        final safeTimestamp = now - 2000;
        await prefs.setInt(lastTsKey, safeTimestamp);
        print('✅ [MessageRemote] First run complete:');
        print('   Processed: $processedCount messages (last 24h)');
        print('   Flagged: $flaggedCount messages');
        print('   Skipped: $skippedOldCount old messages');
        print('ℹ️ [MessageRemote] Next run will process messages newer than: ${DateTime.fromMillisecondsSinceEpoch(safeTimestamp)}');
        return;
      }


      print('💬 [MessageRemote] Total SMS fetched: ${messages.length}');
      print('⏰ [MessageRemote] Last processed timestamp: $lastTimestamp');
      print('🕐 [MessageRemote] Current time: ${DateTime.now().millisecondsSinceEpoch}');
      
      // Show each message with timestamp for debugging
      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final sender = msg.address ?? 'Unknown';
        final body = msg.body ?? '';
        final shortBody = body.length > 30 ? '${body.substring(0, 30)}...' : body;
        final msgTime = msg.date != null ? DateTime.fromMillisecondsSinceEpoch(msg.date!.millisecondsSinceEpoch) : DateTime.now();
        final timeAgo = DateTime.now().difference(msgTime).inMinutes;
        print('📱 [MessageRemote] Message ${i+1}: From $sender - "$shortBody" (${timeAgo}m ago)');
      }
      
      // Calculate 24 hours threshold ONCE (outside loop for performance)
      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
      
      int newMessageCount = 0;
      int analyzedCount = 0;
      int latestTimestamp = lastTimestamp;

      for (final msg in messages) {
        final ts = msg.date?.millisecondsSinceEpoch ?? 0;
        final body = msg.body ?? '';

        // OPTIMIZATION: Check 24 hours filter FIRST (skip old messages immediately, no processing)
        // This prevents unnecessary processing of very old messages
        if (ts < twentyFourHoursAgo) {
          // Silently skip - no need to log thousands of old messages
          continue;
        }
        
        // Skip already processed messages (duplicate check)
        if (ts <= lastTimestamp) {
          // Silently skip - already processed in previous run
          continue;
        }
        
        if (body.trim().isEmpty) continue;
        
        newMessageCount++;
        final sender = msg.address ?? 'unknown';
        print('🆕 [MessageRemote] NEW message found: "${body.length > 40 ? "${body.substring(0, 40)}..." : body}"');
        print('📅 [MessageRemote] Message timestamp: $ts (last: $lastTimestamp)');

        // 🔍 Analyze via Flask
        print('🧠 [MessageRemote] Starting analysis for text: "${body.length > 50 ? "${body.substring(0, 50)}..." : body}"');
        final flagged = await _analyzeAndUpload(
          parentId: parentId,
          childId: childId,
          text: body,
          timestamp: ts,
          sender: sender,
        );

        analyzedCount++;
        if (flagged) print('🚨 [MessageRemote] Suspicious message uploaded.');
        if (ts > latestTimestamp) latestTimestamp = ts;
      }

      // 🕓 Update timestamp only if new messages processed
      // ⚠️ IMPORTANT: Subtract 2000ms safety window to prevent missing new messages
      // Some devices add messages with future timestamps or 1-2 second delay
      if (newMessageCount > 0) {
        // Prevent skip if message timestamp mismatched (future timestamp issue)
        final safeTimestamp = latestTimestamp - 2000;
        await prefs.setInt(lastTsKey, safeTimestamp);
        
        final latestTime = DateTime.fromMillisecondsSinceEpoch(latestTimestamp);
        final safeTime = DateTime.fromMillisecondsSinceEpoch(safeTimestamp);
        
        print('✅ [MessageRemote] Processed $newMessageCount messages, analyzed $analyzedCount');
        print('⏰ [MessageRemote] Updated last processed timestamp');
        print('   Latest message: ${latestTime.toIso8601String()}');
        print('   Safe timestamp: ${safeTime.toIso8601String()} (2s safety window)');
        print('ℹ️ [MessageRemote] Next run will process messages after: ${safeTime.toIso8601String()}');
      } else {
        print('😴 [MessageRemote] No new messages found');
        print('ℹ️ [MessageRemote] All messages are older than: ${DateTime.fromMillisecondsSinceEpoch(lastTimestamp)}');
        print('ℹ️ [MessageRemote] Current time: ${DateTime.now()}');
        print('ℹ️ [MessageRemote] Time difference: ${(DateTime.now().millisecondsSinceEpoch - lastTimestamp) / 1000}s');
        print('ℹ️ [MessageRemote] This means no new messages arrived since the last check');
      }

      print('✅ [MessageRemote] Cycle complete | Checked: ${messages.length}, New: $newMessageCount, Analyzed: $analyzedCount');
    } catch (e) {
      print('❌ [MessageRemote] Error during monitoring: $e');
    }
  }

  /// 🧠 Analyze via Flask and upload flagged ones to Firebase
  Future<bool> _analyzeAndUpload({
    required String parentId,
    required String childId,
    required String text,
    required int timestamp,
    required String sender,
  }) async {
    // First check if sender is in watch list
    try {
      final watchListService = WatchListFirebaseService();
      final isInWatchList = await watchListService.isNumberInWatchList(
        parentId: parentId,
        childId: childId,
        phoneNumber: sender,
      );

      if (isInWatchList) {
        // Contact is in watch list - immediately flag and notify
        final contact = await watchListService.getContactByPhoneNumber(
          parentId: parentId,
          childId: childId,
          phoneNumber: sender,
        );
        
        print('🚨 [MessageRemote] Watch List contact detected: ${contact?.contactName ?? sender}');
        
        // Upload to flagged messages
        await firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('flagged_messages')
            .add({
          'content': text,
          'timestamp': timestamp,
          'sender': sender,
          'tox_label': 'watch_list',
          'tox_score': 1.0,
          'watch_list_contact': contact?.contactName ?? sender,
          'analyzed_at': FieldValue.serverTimestamp(),
          'analysis_source': 'watch_list',
        });
        
        // Send notification immediately
        try {
          final notificationService = NotificationIntegrationService();
          await notificationService.onSuspiciousMessageDetected(
            parentId: parentId,
            childId: childId,
            messageContent: text,
            senderNumber: sender,
            toxLabel: 'Watch List: ${contact?.contactName ?? sender}',
            toxScore: 1.0,
          );
          print('✅ [MessageRemote] Watch List notification sent to parent');
        } catch (e) {
          print('⚠️ [MessageRemote] Error sending watch list notification: $e');
        }
        
        return true; // Flagged due to watch list
      }
    } catch (e) {
      print('ℹ️ [MessageRemote] Watch list check skipped: $e');
    }

    // Continue with normal toxic content analysis
    final urls = [
      'http://192.168.18.41:5000/analyze', // Flask server on LAN (primary)
      'http://127.0.0.1:5000/analyze',     // localhost Flask server
      'http://localhost:5000/analyze',      // localhost alternative
      'http://10.0.2.2:5000/analyze',      // emulator
    ];

    for (final url in urls) {
      try {
        print('🌐 [MessageRemote] POST → $url');
        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'text': text, 'sender': sender, 'timestamp': timestamp}),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final flag = data['flag'] ?? 0;
          final toxLabel = data['tox_label'] ?? data['label'] ?? 'none';
          final toxScore = (data['tox_score'] ?? data['score'] ?? 0.0).toDouble();
          
          print('📊 [MessageRemote] Flask response: flag=$flag, label=$toxLabel, score=$toxScore');

          if (flag == 1) {
            print('🚨 [MessageRemote] Flagged message detected! Uploading to Firebase...');
            await firestore
                .collection('parents')
                .doc(parentId)
                .collection('children')
                .doc(childId)
                .collection('flagged_messages')
                .add({
              'content': text,
              'timestamp': timestamp,
              'sender': sender,
              'tox_label': toxLabel,
              'tox_score': toxScore,
              'analyzed_at': FieldValue.serverTimestamp(),
              'analysis_source': 'flask_server',
            });
            print('✅ [MessageRemote] Flagged message uploaded to Firebase successfully!');
            
            // Send FCM notification to parent
            try {
              final notificationService = NotificationIntegrationService();
              await notificationService.onSuspiciousMessageDetected(
                parentId: parentId,
                childId: childId,
                messageContent: text,
                senderNumber: sender,
                toxLabel: toxLabel,
                toxScore: toxScore,
              );
              print('✅ [MessageRemote] FCM notification sent to parent');
            } catch (e) {
              print('⚠️ [MessageRemote] Error sending FCM notification: $e');
            }
            
            return true;
          } else {
            print('✅ [MessageRemote] Message is clean (not flagged)');
            return false;
          }
        }
      } catch (e) {
        print('⚠️ [Analyzer] Failed to call $url → $e');
        continue;
      }
    }
    print('❌ [MessageRemote] All Flask URLs failed - message not analyzed');
    return false;
  }

  /// 🔍 Fetch flagged messages for parent view
  Future<List<MessageModel>> getFlaggedMessages({
    required String parentId,
    required String childId,
  }) async {
    try {
      final snapshot = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_messages')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel(
          id: doc.id,
          senderId: data['sender'] ?? 'unknown',
          receiverId: childId,
          content: data['content'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
          messageType: 'text',
          childId: childId,
          isSuspicious: true,
          riskScore: (data['tox_score'] ?? 0.0).toDouble(),
          toxicType: data['tox_label'] ?? 'unknown',
          analysisData: data,
        );
      }).toList();
    } catch (e) {
      print('❌ [MessageRemote] Error fetching flagged messages: $e');
      return [];
    }
  }

  /// Check if child is linked to parent
  Future<bool> isChildLinkedToParent({
    required String parentId,
    required String childId,
  }) async {
    try {
      final doc = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('❌ [MessageRemote] Error checking child link: $e');
      return false;
    }
  }

  /// Get messages between parent and child
  Future<List<MessageModel>> getMessages({
    required String parentId,
    required String childId,
  }) async {
    try {
      final snapshot = await firestore
          .collection('messages')
          .where('parentId', isEqualTo: parentId)
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ [MessageRemote] Error fetching messages: $e');
      return [];
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    required String messageType,
    String? parentId,
    String? childId,
  }) async {
    try {
      final messageId = firestore.collection('messages').doc().id;
      
      final message = MessageModel(
        id: messageId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        messageType: messageType,
        parentId: parentId,
        childId: childId,
      );

      await firestore.collection('messages').doc(messageId).set(message.toMap());
    } catch (e) {
      print('❌ [MessageRemote] Error sending message: $e');
      rethrow;
    }
  }

  /// Mark message as suspicious
  Future<void> markMessageAsSuspicious(String messageId, bool isSuspicious) async {
    try {
      await firestore.collection('messages').doc(messageId).update({
        'isSuspicious': isSuspicious,
      });
    } catch (e) {
      print('❌ [MessageRemote] Error updating message: $e');
      rethrow;
    }
  }
}
