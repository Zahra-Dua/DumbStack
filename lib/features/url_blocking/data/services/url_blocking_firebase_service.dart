import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/blocked_url_rule.dart';

/// Service for managing blocked URLs in Firebase
class UrlBlockingFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Block a URL for a child
  Future<void> blockUrl({
    required String childId,
    required String parentId,
    required String url,
    String? reason,
    BlockType blockType = BlockType.domain,
  }) async {
    try {
      // Use Firestore auto-generated ID for stability
      final docRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('blockedUrls')
          .doc();
      
      final ruleId = docRef.id;
      final domain = _extractDomain(url);

      final rule = BlockedUrlRule(
        id: ruleId,
        url: url,
        domain: domain,
        childId: childId,
        parentId: parentId,
        blockedAt: DateTime.now(),
        reason: reason,
        isActive: true,
        blockType: blockType,
      );

      // Store in blockedUrls collection
      await docRef.set(rule.toJson());

      // Also update the visitedUrl document to mark it as blocked
      await _updateVisitedUrlBlockStatus(
        childId: childId,
        parentId: parentId,
        url: url,
        isBlocked: true,
      );

      // Send real-time notification to child device
      await _notifyChildDevice(childId: childId, parentId: parentId);

      // Note: For instant blocking even when child app is backgrounded,
      // implement FCM push notification (see FCM integration example below)
      
      print('✅ URL blocked: $url for child $childId');
    } catch (e) {
      print('❌ Error blocking URL: $e');
      rethrow;
    }
  }

  /// Unblock a URL
  Future<void> unblockUrl({
    required String childId,
    required String parentId,
    required String urlId,
  }) async {
    try {
      // Get the rule to find the URL
      final ruleDoc = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('blockedUrls')
          .doc(urlId)
          .get();

      if (ruleDoc.exists) {
        final rule = BlockedUrlRule.fromJson(ruleDoc.data()!);
        
        // Delete the block rule
        await _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('blockedUrls')
            .doc(urlId)
            .delete();

        // Update visitedUrl document
        await _updateVisitedUrlBlockStatus(
          childId: childId,
          parentId: parentId,
          url: rule.url,
          isBlocked: false,
        );

        // Notify child device
        await _notifyChildDevice(childId: childId, parentId: parentId);

        print('✅ URL unblocked: ${rule.url}');
      }
    } catch (e) {
      print('❌ Error unblocking URL: $e');
      rethrow;
    }
  }

  /// Get all blocked URLs for a child (real-time stream)
  Stream<List<BlockedUrlRule>> getBlockedUrlsStream({
    required String childId,
    required String parentId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('blockedUrls')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BlockedUrlRule.fromDocument(doc)) // Use fromDocument for proper ID handling
          .toList();
    });
  }

  /// Get all blocked URLs (one-time fetch)
  Future<List<BlockedUrlRule>> getBlockedUrls({
    required String childId,
    required String parentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('blockedUrls')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => BlockedUrlRule.fromDocument(doc)) // Use fromDocument for proper ID handling
          .toList();
    } catch (e) {
      print('❌ Error getting blocked URLs: $e');
      return [];
    }
  }

  /// Check if a URL is blocked
  Future<bool> isUrlBlocked({
    required String childId,
    required String parentId,
    required String url,
  }) async {
    try {
      final blockedUrls = await getBlockedUrls(
        childId: childId,
        parentId: parentId,
      );

      return blockedUrls.any((rule) => rule.matches(url));
    } catch (e) {
      print('❌ Error checking if URL is blocked: $e');
      return false;
    }
  }

  /// Update visited URL block status
  Future<void> _updateVisitedUrlBlockStatus({
    required String childId,
    required String parentId,
    required String url,
    required bool isBlocked,
  }) async {
    try {
      // Find all visitedUrls with this URL
      final visitedUrlsSnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .where('url', isEqualTo: url)
          .get();

      final batch = _firestore.batch();
      for (var doc in visitedUrlsSnapshot.docs) {
        batch.update(doc.reference, {
          'isBlocked': isBlocked,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('⚠️ Error updating visited URL block status: $e');
      // Don't throw - this is not critical
    }
  }

  /// Notify child device of block rule changes
  Future<void> _notifyChildDevice({
    required String childId,
    required String parentId,
  }) async {
    try {
      // Create a notification document that child device listens to
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('blockNotifications')
          .add({
        'type': 'blockRulesUpdated',
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'refresh',
      });

      print('✅ Child device notified of block rule changes');
    } catch (e) {
      print('⚠️ Error notifying child device: $e');
      // Don't throw - notification is best effort
    }
  }

  /// Generate unique rule ID from URL (deprecated - now using Firestore auto ID)
  /// Kept for backward compatibility if needed
  @Deprecated('Use Firestore auto-generated doc ID instead')
  String _generateRuleId(String url) {
    // Use URL hash as ID for consistency (deprecated - not stable across runs)
    return url.hashCode.abs().toString();
  }

  /// Extract domain from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      final regex = RegExp(r'https?://([^/]+)');
      final match = regex.firstMatch(url);
      return match?.group(1) ?? url;
    }
  }
}

