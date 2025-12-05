import 'package:firebase_messaging/firebase_messaging.dart';
import 'child_url_blocker_service.dart';

/// Handler for FCM messages related to URL blocking
/// Integrates with ChildUrlBlockerService to refresh rules when FCM received
class FcmBlockHandler {
  final ChildUrlBlockerService blockerService;

  FcmBlockHandler(this.blockerService);

  /// Initialize FCM listener for block rule updates
  /// Call this in child app initialization
  void initializeFcmListener() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleBlockUpdateMessage(message);
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleBlockUpdateMessage(message);
    });

    // Handle notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleBlockUpdateMessage(message);
      }
    });

    print('✅ FCM block handler initialized');
  }

  /// Handle FCM message for block rule updates
  void _handleBlockUpdateMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    if (type == 'blockRulesUpdated') {
      print('🔔 FCM: Block rules updated, refreshing...');
      
      // Trigger refresh of block rules
      // The blockerService will reload rules from Firestore
      // This is handled by the existing stream listener, but we can force refresh
      _refreshBlockRules();
    }
  }

  /// Force refresh block rules from Firestore
  Future<void> _refreshBlockRules() async {
    try {
      // Re-initialize to reload rules
      await blockerService.initialize();
      print('✅ Block rules refreshed via FCM');
    } catch (e) {
      print('❌ Error refreshing block rules: $e');
    }
  }
}

