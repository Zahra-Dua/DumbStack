import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class DeleteChildService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  /// Delete child and all associated data from Firebase
  Future<bool> deleteChild({
    required String parentId,
    required String childId,
    String? childName, // Optional child name for notification
  }) async {
    try {
      print('🗑️ [DeleteChild] Starting deletion for child: $childId');

      // Get child name before deletion (if not provided)
      String? name = childName;
      if (name == null) {
        try {
          final childDoc = await _firestore
              .collection('parents')
              .doc(parentId)
              .collection('children')
              .doc(childId)
              .get();
          if (childDoc.exists) {
            final data = childDoc.data();
            name = data?['name'] ?? data?['firstName'] ?? 'Child';
          }
        } catch (e) {
          print('⚠️ [DeleteChild] Could not fetch child name: $e');
          name = 'Child';
        }
      }

      // 🔥 Show notification IMMEDIATELY (before slow delete operations)
      await _showDeleteNotification(name ?? 'Child');
      print('✅ [DeleteChild] Notification shown immediately');

      // Delete operations - run in parallel for faster deletion
      await Future.wait([
        // 1. Delete child's location data
        _deleteLocationData(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting location: $e');
        }),
        
        // 2. Delete child's flagged messages
        _deleteFlaggedMessages(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting flagged messages: $e');
        }),
        
        // 3. Delete child's flagged calls
        _deleteFlaggedCalls(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting flagged calls: $e');
        }),
        
        // 4. Delete child's call logs
        _deleteCallLogs(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting call logs: $e');
        }),
        
        // 5. Delete child's URL tracking data
        _deleteUrlTrackingData(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting URL tracking: $e');
        }),
        
        // 6. Delete child's app usage data
        _deleteAppUsageData(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting app usage: $e');
        }),
        
        // 7. Delete child's watch list
        _deleteWatchList(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting watch list: $e');
        }),
        
        // 8. Delete child's blocked URLs
        _deleteBlockedUrls(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting blocked URLs: $e');
        }),
        
        // 9. Delete child's geofence data
        _deleteGeofenceData(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting geofence: $e');
        }),
        
        // 10. Delete child's general messages
        _deleteMessages(parentId, childId).catchError((e) {
          print('⚠️ [DeleteChild] Error deleting messages: $e');
        }),
      ], eagerError: false);
      
      // 11. Delete child document from parent's children collection (MOST IMPORTANT)
      final childDocRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId);
      
      // Verify document exists before deletion
      final childDoc = await childDocRef.get();
      if (childDoc.exists) {
        await childDocRef.delete();
        print('✅ [DeleteChild] Child document deleted');
        
        // Verify deletion
        final verifyDoc = await childDocRef.get();
        if (verifyDoc.exists) {
          print('⚠️ [DeleteChild] WARNING: Child document still exists after deletion! Retrying...');
          // Retry deletion
          await childDocRef.delete();
          // Verify again
          final verifyDoc2 = await childDocRef.get();
          if (verifyDoc2.exists) {
            print('❌ [DeleteChild] ERROR: Child document still exists after retry!');
            throw Exception('Failed to delete child document after retry');
          }
        }
      } else {
        print('⚠️ [DeleteChild] Child document does not exist (may have been already deleted)');
      }

      // 12. Remove child ID from parent's childrenIds array
      await _firestore
          .collection('parents')
          .doc(parentId)
          .update({
            'childrenIds': FieldValue.arrayRemove([childId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      print('✅ [DeleteChild] Child ID removed from parent\'s childrenIds array');

      // 13. Clear child's local data
      await _clearChildLocalData(childId).catchError((e) {
        print('⚠️ [DeleteChild] Error clearing local data: $e');
      });

      // 14. Clean up orphaned childrenIds (sync childrenIds with actual documents)
      await _cleanupOrphanedChildrenIds(parentId).catchError((e) {
        print('⚠️ [DeleteChild] Error cleaning up orphaned childrenIds: $e');
      });

      print('✅ [DeleteChild] Child $childId deleted successfully');
      return true;
    } catch (e) {
      print('❌ [DeleteChild] Error deleting child: $e');
      return false;
    }
  }

  /// Clean up orphaned childrenIds - sync parent's childrenIds array with actual child documents
  Future<void> _cleanupOrphanedChildrenIds(String parentId) async {
    try {
      // Get actual child documents
      final childrenSnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .get();
      
      final actualChildIds = childrenSnapshot.docs.map((doc) => doc.id).toSet();
      
      // Get parent's childrenIds array
      final parentDoc = await _firestore
          .collection('parents')
          .doc(parentId)
          .get();
      
      if (!parentDoc.exists) {
        return;
      }
      
      final parentData = parentDoc.data();
      final childrenIds = (parentData?['childrenIds'] as List<dynamic>? ?? [])
          .map((id) => id.toString())
          .toSet();
      
      // Find orphaned IDs (in childrenIds but not in actual documents)
      final orphanedIds = childrenIds.difference(actualChildIds);
      
      // Find missing IDs (in actual documents but not in childrenIds)
      final missingIds = actualChildIds.difference(childrenIds);
      
      if (orphanedIds.isNotEmpty || missingIds.isNotEmpty) {
        print('🔧 [DeleteChild] Cleaning up childrenIds array...');
        print('   Orphaned IDs (removing): $orphanedIds');
        print('   Missing IDs (adding): $missingIds');
        
        // Update childrenIds to match actual documents
        await _firestore
            .collection('parents')
            .doc(parentId)
            .update({
              'childrenIds': actualChildIds.toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        print('✅ [DeleteChild] childrenIds array synced with actual documents');
      }
    } catch (e) {
      print('⚠️ [DeleteChild] Error cleaning up orphaned childrenIds: $e');
      // Don't throw - this is a cleanup operation, shouldn't fail the main deletion
    }
  }

  /// Delete child's location data
  Future<void> _deleteLocationData(String parentId, String childId) async {
    try {
      final locationRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('location');

      // Delete current location
      await locationRef.doc('current').delete();

      // Delete location history (batch delete)
      final locationHistory = await locationRef.get();
      final batch = _firestore.batch();
      
      for (final doc in locationHistory.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] Location data deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting location data: $e');
    }
  }

  /// Delete child's flagged messages
  Future<void> _deleteFlaggedMessages(String parentId, String childId) async {
    try {
      final flaggedMessagesRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_messages');

      // Batch delete all flagged messages
      final flaggedMessages = await flaggedMessagesRef.get();
      final batch = _firestore.batch();
      
      for (final doc in flaggedMessages.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] Flagged messages deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting flagged messages: $e');
    }
  }

  /// Delete child's geofence data
  Future<void> _deleteGeofenceData(String parentId, String childId) async {
    try {
      final geofenceRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('geofences');

      // Batch delete all geofences
      final geofences = await geofenceRef.get();
      final batch = _firestore.batch();
      
      for (final doc in geofences.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] Geofence data deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting geofence data: $e');
    }
  }

  /// Delete child's general messages
  Future<void> _deleteMessages(String parentId, String childId) async {
    try {
      final messagesRef = _firestore.collection('messages');
      
      // Delete messages where childId matches
      final messages = await messagesRef
          .where('childId', isEqualTo: childId)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] General messages deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting general messages: $e');
    }
  }

  /// Delete child's flagged calls
  Future<void> _deleteFlaggedCalls(String parentId, String childId) async {
    try {
      final flaggedCallsRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('flagged_calls');

      // Batch delete all flagged calls
      final flaggedCalls = await flaggedCallsRef.get();
      final batch = _firestore.batch();
      
      for (final doc in flaggedCalls.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] Flagged calls deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting flagged calls: $e');
    }
  }

  /// Delete child's call logs
  Future<void> _deleteCallLogs(String parentId, String childId) async {
    try {
      final callLogsRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('call_logs');

      // Batch delete all call logs
      final callLogs = await callLogsRef.get();
      final batch = _firestore.batch();
      
      for (final doc in callLogs.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] Call logs deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting call logs: $e');
    }
  }

  /// Delete child's URL tracking data
  Future<void> _deleteUrlTrackingData(String parentId, String childId) async {
    try {
      final urlTrackingRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls');

      // Batch delete all visited URLs
      final visitedUrls = await urlTrackingRef.get();
      final batch = _firestore.batch();
      
      for (final doc in visitedUrls.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] URL tracking data deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting URL tracking data: $e');
    }
  }

  /// Delete child's app usage data
  Future<void> _deleteAppUsageData(String parentId, String childId) async {
    try {
      final appUsageRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage');

      // Batch delete all app usage data
      final appUsage = await appUsageRef.get();
      final batch = _firestore.batch();
      
      for (final doc in appUsage.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] App usage data deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting app usage data: $e');
    }
  }

  /// Delete child's watch list
  Future<void> _deleteWatchList(String parentId, String childId) async {
    try {
      final watchListRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('watchList');

      // Batch delete all watch list contacts
      final watchList = await watchListRef.get();
      final batch = _firestore.batch();
      
      for (final doc in watchList.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] Watch list deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting watch list: $e');
    }
  }

  /// Delete child's blocked URLs
  Future<void> _deleteBlockedUrls(String parentId, String childId) async {
    try {
      final blockedUrlsRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('blockedUrls');

      // Batch delete all blocked URLs
      final blockedUrls = await blockedUrlsRef.get();
      final batch = _firestore.batch();
      
      for (final doc in blockedUrls.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('✅ [DeleteChild] Blocked URLs deleted');
    } catch (e) {
      print('⚠️ [DeleteChild] Error deleting blocked URLs: $e');
    }
  }

  /// Clear child's local data from SharedPreferences
  Future<void> _clearChildLocalData(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove child-specific data
      await prefs.remove('child_uid');
      await prefs.remove('parent_uid');
      await prefs.remove('last_message_timestamp_$childId');
      await prefs.remove('last_call_log_timestamp_$childId');
      await prefs.remove('last_suspicious_call_timestamp_$childId');
      
      print('✅ [DeleteChild] Local data cleared');
    } catch (e) {
      print('⚠️ [DeleteChild] Error clearing local data: $e');
    }
  }

  /// Show notification in status bar when child is deleted
  Future<void> _showDeleteNotification(String childName) async {
    try {
      // Create notification channel first (if not exists)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'child_deleted_channel',
        'Child Deleted Notifications',
        description: 'Notifications when a child is deleted',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        print('✅ [DeleteChild] Notification channel created');
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'child_deleted_channel',
        'Child Deleted Notifications',
        channelDescription: 'Notifications when a child is deleted',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: Color(0xFF007AFF),
        ticker: 'Child deleted',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Child Deleted',
        '$childName deleted successfully',
        platformChannelSpecifics,
        payload: 'child_deleted',
      );

      print('✅ [DeleteChild] Notification shown: $childName deleted');
    } catch (e) {
      print('❌ [DeleteChild] Error showing notification: $e');
    }
  }
}
