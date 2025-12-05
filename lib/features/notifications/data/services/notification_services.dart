import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Simple Notification Services class for handling Firebase Messaging
/// Similar to the pattern shown in the image
class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Request notification permission
  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    print('🔔 Notification Permission: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else {
      print('❌ Notification permission denied');
    }
  }

  /// Initialize local notifications
  void initLocalNotifications() {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      androidImplementation.createNotificationChannel(channel);
      print('✅ Notification channel created');
    }
  }

  /// Initialize Firebase Messaging
  void firebaseInit() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      print('📨 Foreground message received');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      // Show local notification
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('🔔 Notification opened app: ${message.messageId}');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
    });

    print('✅ Firebase Messaging initialized');
  }

  /// Show local notification
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFF007AFF),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title ?? 'Notification',
      notification.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );

    print('✅ Local notification shown');
  }

  /// Get device FCM token
  Future<String> getDeviceToken() async {
    String? token = await messaging.getToken();
    if (token != null) {
      print('📱 FCM Token: $token');
      return token;
    } else {
      throw Exception('FCM Token is null - unable to get device token');
    }
  }
}

