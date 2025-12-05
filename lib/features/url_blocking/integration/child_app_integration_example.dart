/// Example integration of URL blocking in child app
/// 
/// Add this to your child app's main screen initialization
library;

import 'package:flutter/material.dart';
import 'package:parental_control_app/features/url_blocking/data/services/child_url_blocker_service.dart';
import 'package:parental_control_app/features/url_blocking/data/services/child_browser_interceptor.dart';
import 'package:parental_control_app/features/url_blocking/data/services/fcm_block_handler.dart';
import 'package:parental_control_app/features/url_blocking/data/services/fcm_block_notification_service.dart';
import 'package:parental_control_app/features/url_blocking/presentation/widgets/blocked_webview_wrapper.dart';

class ChildAppUrlBlockingIntegration {
  static ChildUrlBlockerService? _blockerService;
  static ChildBrowserInterceptor? _interceptor;
  static FcmBlockHandler? _fcmHandler;
  static FcmBlockNotificationService? _fcmService;

  /// Initialize URL blocking in child app
  /// Call this in your child app's main screen initState
  static Future<void> initialize({
    String? parentId, // Pass parentId if available
    String? childId, // Pass childId if available
  }) async {
    try {
      _blockerService = ChildUrlBlockerService();
      
      // Set callback for when URL is blocked
      _blockerService!.onUrlBlocked = (url, rule) {
        print('🚫 URL blocked: $url');
        print('   Reason: ${rule.reason ?? "Blocked by parent"}');
        // Optional: Log blocked attempt to analytics
      };

      // Initialize the blocker
      await _blockerService!.initialize();

      // Create interceptor
      _interceptor = ChildBrowserInterceptor(_blockerService!);

      // Initialize FCM handler for background updates
      if (_blockerService != null) {
        _fcmHandler = FcmBlockHandler(_blockerService!);
        _fcmHandler!.initializeFcmListener();
      }

      // Register FCM token for push notifications
      if (parentId != null && childId != null) {
        _fcmService = FcmBlockNotificationService();
        await _fcmService!.registerChildFcmToken(
          childId: childId,
          parentId: parentId,
        );
      }

      print('✅ URL blocking initialized successfully with FCM support');
    } catch (e) {
      print('❌ Error initializing URL blocking: $e');
    }
  }

  /// Get blocker service instance
  static ChildUrlBlockerService? get blockerService => _blockerService;

  /// Get interceptor instance
  static ChildBrowserInterceptor? get interceptor => _interceptor;

  /// Check if URL should be blocked (before launching)
  static bool shouldBlockUrl(String url) {
    return _blockerService?.shouldBlockUrl(url) ?? false;
  }

  /// Create a blocking WebView wrapper
  /// Use this instead of regular WebView in child app
  static Widget createBlockingWebView({
    required String initialUrl,
    required BuildContext context,
  }) {
    if (_blockerService == null) {
      throw Exception('URL blocking not initialized. Call initialize() first.');
    }

    return BlockedWebViewWrapper(
      initialUrl: initialUrl,
      blockerService: _blockerService!,
    );
  }

  /// Dispose resources
  static void dispose() {
    _blockerService?.dispose();
    _blockerService = null;
    _interceptor = null;
    _fcmHandler = null;
    _fcmService = null;
  }
}
