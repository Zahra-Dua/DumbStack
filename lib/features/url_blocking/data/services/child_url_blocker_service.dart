import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/blocked_url_rule.dart';
import 'url_blocking_firebase_service.dart';

/// Service that runs on child device to enforce URL blocking
class ChildUrlBlockerService {
  final UrlBlockingFirebaseService _blockingService = UrlBlockingFirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<BlockedUrlRule> _blockedUrls = [];
  StreamSubscription? _blockRulesSubscription;
  StreamSubscription? _notificationSubscription;
  bool _isInitialized = false;

  /// Callback when URL is blocked
  Function(String url, BlockedUrlRule rule)? onUrlBlocked;

  /// Initialize the blocker service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ No user logged in, cannot initialize URL blocker');
        return;
      }

      // Get child and parent IDs (assuming child's UID is stored)
      final childId = currentUser.uid;
      final parentId = await _getParentId(childId);

      if (parentId == null) {
        print('⚠️ Parent ID not found for child $childId');
        return;
      }

      // Load initial blocked URLs
      await _loadBlockedUrls(childId: childId, parentId: parentId);

      // Listen for real-time updates
      _startListening(childId: childId, parentId: parentId);

      _isInitialized = true;
      print('✅ URL Blocker Service initialized');
    } catch (e) {
      print('❌ Error initializing URL blocker: $e');
    }
  }

  /// Check if a URL should be blocked
  bool shouldBlockUrl(String url) {
    if (!_isInitialized || _blockedUrls.isEmpty) return false;

    for (var rule in _blockedUrls) {
      if (rule.matches(url)) {
        // Notify callback
        onUrlBlocked?.call(url, rule);
        return true;
      }
    }

    return false;
  }

  /// Get blocking reason for a URL
  String? getBlockReason(String url) {
    for (var rule in _blockedUrls) {
      if (rule.matches(url)) {
        return rule.reason ?? 'This URL has been blocked by parent';
      }
    }
    return null;
  }

  /// Load blocked URLs from Firebase
  Future<void> _loadBlockedUrls({
    required String childId,
    required String parentId,
  }) async {
    try {
      _blockedUrls = await _blockingService.getBlockedUrls(
        childId: childId,
        parentId: parentId,
      );
      print('✅ Loaded ${_blockedUrls.length} blocked URL rules');
    } catch (e) {
      print('❌ Error loading blocked URLs: $e');
    }
  }

  /// Start listening for real-time block rule updates
  void _startListening({
    required String childId,
    required String parentId,
  }) {
    // Listen to blockedUrls collection
    _blockRulesSubscription = _blockingService
        .getBlockedUrlsStream(childId: childId, parentId: parentId)
        .listen(
      (blockedUrls) {
        _blockedUrls = blockedUrls;
        print('🔄 Block rules updated: ${_blockedUrls.length} rules active');
      },
      onError: (error) {
        print('❌ Error in block rules stream: $error');
      },
    );

    // Listen to block notifications for immediate updates
    _notificationSubscription = _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('blockNotifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          print('🔔 Block rules notification received, refreshing...');
          _loadBlockedUrls(childId: childId, parentId: parentId);
        }
      },
      onError: (error) {
        print('❌ Error in notification stream: $error');
      },
    );
  }

  /// Get parent ID for a child
  /// Uses the same method as pairing_remote_datasource
  Future<String?> _getParentId(String childId) async {
    try {
      // Query all parents to find which one has this child
      // This is the same approach used in pairing_remote_datasource
      final parentsQuery = await _firestore.collection('parents').get();
      
      for (final parentDoc in parentsQuery.docs) {
        final childDoc = await _firestore
            .collection('parents')
            .doc(parentDoc.id)
            .collection('children')
            .doc(childId)
            .get();
        
        if (childDoc.exists) {
          return parentDoc.id;
        }
      }
      
      print('⚠️ Parent ID not found for child $childId');
      return null;
    } catch (e) {
      print('❌ Error getting parent ID: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _blockRulesSubscription?.cancel();
    _notificationSubscription?.cancel();
    _isInitialized = false;
    _blockedUrls.clear();
  }

  /// Get current blocked URLs count
  int get blockedUrlsCount => _blockedUrls.length;
}

