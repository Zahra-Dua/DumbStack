import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parental_control_app/core/di/service_locator.dart';
import 'package:parental_control_app/features/user_management/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:parental_control_app/features/notifications/data/services/fcm_service.dart';
import 'package:parental_control_app/features/notifications/data/services/notification_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/constants/app_colors.dart';
import 'core/di/service_locator.dart' as di;
import 'features/user_management/presentation/pages/splash_screen.dart';
import 'firebase_options.dart';

// ✅ Import WorkManager service
// import 'package:parental_control_app/features/messaging/data/services/workmanager_message_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Use the notification handler's background handler
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize service locator FIRST (needed for app to start)
  await di.initServiceLocator();
  print('✅ Service locator initialized');
  
  // Initialize FCM background handler (non-blocking)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize local notifications (fast, non-blocking)
  print('🔔 Initializing local notifications...');
  initializeLocalNotifications().then((_) {
    print('✅ Local notifications initialized');
  }).catchError((e) {
    print('⚠️ Error initializing local notifications: $e');
  });
  
  // Set up foreground message handler (non-blocking)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📨 Foreground message received');
    handleForegroundMessage(message);
    
    final notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? message.data['title'] ?? 'SafeNest Alert',
        notification.body ?? message.data['body'] ?? 'You have a new notification',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
        ),
      );
    }
  });
  
  // Handle notification taps when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🔔 Notification clicked: ${message.messageId}');
  });
  
  // Initialize FCM service in background (non-blocking - won't delay login)
  print('🔔 Starting FCM initialization in background...');
  _initializeFCMInBackground();
  
  // Check if app was opened from a notification (non-blocking)
  FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
    if (initialMessage != null) {
      print('🔔 App opened from notification: ${initialMessage.messageId}');
    }
  });

  // Start app immediately (don't wait for FCM)
  runApp(const SafeNestApp());
}

/// Initialize FCM service in background (non-blocking)
void _initializeFCMInBackground() {
  Future.microtask(() async {
    try {
      // Request notification permission
      print('🔔 Requesting notification permission...');
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      
      print('🔔 Notification permission: ${settings.authorizationStatus}');
      
      // Initialize FCM service (this may take time, but won't block login)
      await FCMService().initialize();
      print('✅ FCM service initialized');
    } catch (e) {
      print('⚠️ Error initializing FCM in background: $e');
      // Don't block app if FCM fails
    }
  });
}

class SafeNestApp extends StatelessWidget {
  const SafeNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()),
        // Add other BlocProviders here if you have them
      ],
      child: MaterialApp(
        title: 'SafeNest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.offWhite,
          primaryColor: AppColors.darkCyan,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.lightCyan,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.black),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
