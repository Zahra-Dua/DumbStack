import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MessagePermissionService {
  /// Request all necessary permissions for message monitoring
  static Future<bool> requestMessagePermissions() async {
    try {
      // Request SMS permissions
      final smsStatus = await Permission.sms.request();
      if (smsStatus != PermissionStatus.granted) {
        print('SMS permission denied');
        return false;
      }

      // Request phone permissions
      final phoneStatus = await Permission.phone.request();
      if (phoneStatus != PermissionStatus.granted) {
        print('Phone permission denied');
        return false;
      }

      // Request notification permissions (for message monitoring)
      final notificationStatus = await Permission.notification.request();
      if (notificationStatus != PermissionStatus.granted) {
        print('Notification permission denied');
        return false;
      }

      // Request system alert window permission
      final systemAlertStatus = await Permission.systemAlertWindow.request();
      if (systemAlertStatus != PermissionStatus.granted) {
        print('System alert window permission denied');
        return false;
      }

      print('All message permissions granted');
      return true;
    } catch (e) {
      print('Error requesting message permissions: $e');
      return false;
    }
  }

  /// Check if all message permissions are granted
  static Future<bool> checkMessagePermissions() async {
    try {
      // Check SMS permission
      final smsStatus = await Permission.sms.status;
      if (smsStatus != PermissionStatus.granted) {
        return false;
      }

      // Check phone permission
      final phoneStatus = await Permission.phone.status;
      if (phoneStatus != PermissionStatus.granted) {
        return false;
      }

      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      if (notificationStatus != PermissionStatus.granted) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking message permissions: $e');
      return false;
    }
  }

  /// Show permission dialog with explanation
  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message Monitoring Permissions'),
          content: const Text(
            'To monitor your child\'s messages for safety, we need access to:\n\n'
            '• SMS messages\n'
            '• Phone calls\n'
            '• Notifications\n\n'
            'This helps us detect and flag suspicious or harmful content.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final granted = await requestMessagePermissions();
                if (!granted) {
                  _showPermissionDeniedDialog(context);
                }
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }

  /// Show permission denied dialog
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Message monitoring requires SMS and phone permissions. '
            'Please enable them in app settings to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Get permission status for display
  static Future<Map<String, bool>> getPermissionStatus() async {
    return {
      'sms': await Permission.sms.status == PermissionStatus.granted,
      'phone': await Permission.phone.status == PermissionStatus.granted,
      'notification': await Permission.notification.status == PermissionStatus.granted,
      'systemAlert': await Permission.systemAlertWindow.status == PermissionStatus.granted,
    };
  }
}
