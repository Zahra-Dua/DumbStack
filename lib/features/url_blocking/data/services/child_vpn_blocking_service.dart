import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'url_blocking_firebase_service.dart';
import '../../../url_tracking/data/services/url_tracking_firebase_service.dart';

/// Service that manages DNS-based VPN blocking on child device
/// Listens to Firestore for blocked URLs and updates VPN service in real-time
class ChildVpnBlockingService {
  static const MethodChannel _channel = MethodChannel('child_vpn');
  
  final UrlBlockingFirebaseService _blockingService = UrlBlockingFirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UrlTrackingFirebaseService _urlTrackingService = UrlTrackingFirebaseService();

  StreamSubscription? _blockRulesSubscription;
  bool _isInitialized = false;
  bool _isVpnRunning = false;
  String? _parentId;
  String? _childId;

  /// Initialize the VPN blocking service
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ [VPNBlocking] Already initialized');
      return;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ [VPNBlocking] No user logged in, cannot initialize');
        return;
      }

      // Get child and parent IDs
      _childId = currentUser.uid;
      _parentId = await _getParentId(_childId!);

      if (_parentId == null) {
        print('⚠️ [VPNBlocking] Parent ID not found for child $_childId');
        return;
      }

      print('🚀 [VPNBlocking] Initializing VPN blocking service...');
      print('   Child ID: $_childId');
      print('   Parent ID: $_parentId');

      // Set up MethodChannel handler for URL logging
      _channel.setMethodCallHandler(_handleMethodCall);

      // Request VPN permission and start VPN
      final vpnStarted = await _startVpn();
      if (!vpnStarted) {
        print('❌ [VPNBlocking] Failed to start VPN service');
        return;
      }

      // Load initial blocked URLs and update VPN
      await _loadAndUpdateBlockedUrls();

      // Listen for real-time updates
      _startListening();

      _isInitialized = true;
      print('✅ [VPNBlocking] VPN blocking service initialized');
    } catch (e) {
      print('❌ [VPNBlocking] Error initializing: $e');
    }
  }

  /// Handle MethodChannel calls from Android
  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      if (call.method == 'logVisitedUrl') {
        final url = call.arguments['url'] as String?;
        if (url != null) {
          await logVisitedUrl(url);
        }
      }
    } catch (e) {
      print('❌ [VPNBlocking] Error handling method call: $e');
    }
  }

  /// Start VPN service (requests permission if needed)
  Future<bool> _startVpn() async {
    try {
      // Request VPN permission
      final hasPermission = await _channel.invokeMethod<bool>('requestVpnPermission');
      if (hasPermission != true) {
        print('⚠️ [VPNBlocking] VPN permission not granted');
        return false;
      }

      // Start VPN service
      await _channel.invokeMethod('startVpn');
      _isVpnRunning = true;
      print('✅ [VPNBlocking] VPN service started');
      return true;
    } on PlatformException catch (e) {
      print('❌ [VPNBlocking] Error starting VPN: ${e.message}');
      return false;
    }
  }

  /// Load blocked URLs from Firebase and update VPN
  Future<void> _loadAndUpdateBlockedUrls() async {
    try {
      if (_parentId == null || _childId == null) return;

      final blockedUrls = await _blockingService.getBlockedUrls(
        childId: _childId!,
        parentId: _parentId!,
      );

      // Extract domains from blocked URLs
      final domains = blockedUrls
          .where((rule) => rule.isActive)
          .map((rule) => rule.domain ?? _extractDomain(rule.url))
          .where((domain) => domain.isNotEmpty)
          .toSet()
          .toList();

      print('📋 [VPNBlocking] Loaded ${domains.length} blocked domains');
      
      // Update VPN with blocked domains
      await _updateVpnBlockedDomains(domains);
    } catch (e) {
      print('❌ [VPNBlocking] Error loading blocked URLs: $e');
    }
  }

  /// Update VPN service with blocked domains
  Future<void> _updateVpnBlockedDomains(List<String> domains) async {
    try {
      if (!_isVpnRunning) {
        print('⚠️ [VPNBlocking] VPN not running, cannot update domains');
        return;
      }

      await _channel.invokeMethod('updateBlockedUrls', {'urls': domains});
      print('✅ [VPNBlocking] Updated VPN with ${domains.length} blocked domains');
    } on PlatformException catch (e) {
      print('❌ [VPNBlocking] Error updating VPN domains: ${e.message}');
    }
  }

  /// Start listening for real-time block rule updates
  void _startListening() {
    if (_parentId == null || _childId == null) return;

    // Listen to blockedUrls collection
    _blockRulesSubscription = _blockingService
        .getBlockedUrlsStream(childId: _childId!, parentId: _parentId!)
        .listen(
      (blockedUrls) async {
        print('🔄 [VPNBlocking] Block rules updated: ${blockedUrls.length} rules active');
        
        // Extract domains and update VPN
        final domains = blockedUrls
            .where((rule) => rule.isActive)
            .map((rule) => rule.domain ?? _extractDomain(rule.url))
            .where((domain) => domain.isNotEmpty)
            .toSet()
            .toList();

        await _updateVpnBlockedDomains(domains);
      },
      onError: (error) {
        print('❌ [VPNBlocking] Error in block rules stream: $error');
      },
    );
  }

  /// Log visited URL to Firestore (called from VPN service when URL is attempted)
  Future<void> logVisitedUrl(String url) async {
    try {
      if (_parentId == null || _childId == null) return;

      // Extract domain (url is already a domain from DNS query)
      final domain = url;
      final fullUrl = !url.startsWith('http') ? 'https://$url' : url;
      
      // Log to visitedUrls collection
      await _urlTrackingService.uploadUrlToFirebase(
        url: fullUrl,
        title: domain,
        packageName: 'system', // VPN intercepts all traffic
        childId: _childId!,
        parentId: _parentId!,
        browserName: 'VPN Intercept',
        metadata: {
          'source': 'vpn_dns_blocking',
          'domain': domain,
        },
      );

      print('📝 [VPNBlocking] Logged visited URL: $url');
    } catch (e) {
      print('❌ [VPNBlocking] Error logging visited URL: $e');
    }
  }

  /// Extract domain from URL
  String _extractDomain(String url) {
    try {
      // Remove protocol if present
      String cleanUrl = url;
      if (url.contains('://')) {
        cleanUrl = url.split('://')[1];
      }
      
      // Remove path, query, fragment
      cleanUrl = cleanUrl.split('/').first;
      cleanUrl = cleanUrl.split('?').first;
      cleanUrl = cleanUrl.split('#').first;
      
      // Remove port if present
      if (cleanUrl.contains(':')) {
        cleanUrl = cleanUrl.split(':').first;
      }
      
      return cleanUrl.toLowerCase().trim();
    } catch (e) {
      // Fallback: return as-is
      return url.toLowerCase().trim();
    }
  }

  /// Get parent ID for a child
  Future<String?> _getParentId(String childId) async {
    try {
      // Query all parents to find which one has this child
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
      
      return null;
    } catch (e) {
      print('❌ [VPNBlocking] Error getting parent ID: $e');
      return null;
    }
  }

  /// Stop VPN service
  Future<void> stopVpn() async {
    try {
      await _channel.invokeMethod('stopVpn');
      _isVpnRunning = false;
      print('🛑 [VPNBlocking] VPN service stopped');
    } on PlatformException catch (e) {
      print('❌ [VPNBlocking] Error stopping VPN: ${e.message}');
    }
  }

  /// Dispose resources
  void dispose() {
    _blockRulesSubscription?.cancel();
    _channel.setMethodCallHandler(null);
    _isInitialized = false;
    _isVpnRunning = false;
  }

  /// Check if VPN is running
  bool get isVpnRunning => _isVpnRunning;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

