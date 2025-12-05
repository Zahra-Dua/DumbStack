# Notification & Alert System Module

Complete FCM-based notification system for SafeNest Parental Control App.

## Features

### ✅ Module 07: Notification & Alert System

- **FE-1**: Real-time notifications to parents for suspicious activities or rule violations
- **FE-2**: SOS feature for children to alert parents in emergencies
- **FE-3**: Alerts for emotional distress based on activity and content analysis
- **FE-4**: Emergency alerts for unsafe locations (geofencing)
- **FE-5**: Predictive alerts based on behavioral trends and usage patterns

## Alert Types

1. **Suspicious Message Alert** - When toxic/harassment messages are detected
2. **Suspicious Call Alert** - When suspicious calls are detected
3. **Geofencing Alert** - When child enters/exits safe zones
4. **SOS Alert** - Emergency alert from child
5. **Screen Time Limit Alert** - When daily screen time limit is reached
6. **App/Website Blocked Alert** - When child tries to access blocked content
7. **Emotional Distress Alert** - AI-detected emotional distress
8. **Toxic Behavior Pattern Alert** - Pattern-based toxic behavior detection
9. **Suspicious Contacts Pattern Alert** - Pattern-based contact analysis
10. **Predictive Threat Alert** - AI-based predictive threat detection

## Architecture

```
lib/features/notifications/
├── domain/
│   ├── entities/
│   │   ├── alert_type.dart
│   │   └── notification_entity.dart
│   ├── repositories/
│   │   └── notification_repository.dart
│   └── usecases/
│       ├── get_notifications_usecase.dart
│       ├── stream_notifications_usecase.dart
│       └── mark_notification_read_usecase.dart
├── data/
│   ├── datasources/
│   │   └── notification_remote_datasource.dart
│   ├── models/
│   │   └── notification_model.dart
│   ├── repositories/
│   │   └── notification_repository_impl.dart
│   └── services/
│       ├── fcm_service.dart
│       ├── notification_handler.dart
│       ├── alert_sender_service.dart
│       └── notification_integration_service.dart
└── presentation/
    ├── bloc/
    │   ├── notification_bloc.dart
    │   ├── notification_event.dart
    │   └── notification_state.dart
    ├── pages/
    │   ├── notifications_screen.dart
    │   └── sos_emergency_screen.dart
    └── widgets/
        └── notification_card.dart
```

## Setup

### 1. Firebase Configuration

FCM is already configured in `firebase_options.dart`. Make sure:
- Firebase project has Cloud Messaging enabled
- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly configured

### 2. Android Configuration

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 3. iOS Configuration

Add to `Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

## Usage

### Sending Alerts

```dart
import 'package:parental_control_app/features/notifications/data/services/alert_sender_service.dart';

final alertSender = AlertSenderService();

// Send suspicious message alert
await alertSender.sendSuspiciousMessageAlert(
  parentId: 'parent123',
  childId: 'child456',
  messageContent: 'Toxic message content',
  senderNumber: '+1234567890',
  toxLabel: 'Harassment',
  toxScore: 0.95,
);

// Send SOS alert
await alertSender.sendSOSAlert(
  parentId: 'parent123',
  childId: 'child456',
  latitude: 37.7749,
  longitude: -122.4194,
  address: '123 Main St',
);
```

### Using Integration Service

```dart
import 'package:parental_control_app/features/notifications/data/services/notification_integration_service.dart';

final integrationService = NotificationIntegrationService();

// When suspicious message detected
await integrationService.onSuspiciousMessageDetected(
  parentId: parentId,
  childId: childId,
  messageContent: message,
  senderNumber: sender,
  toxLabel: 'Toxic',
  toxScore: 0.9,
);
```

### Displaying Notifications

```dart
import 'package:parental_control_app/features/notifications/presentation/pages/notifications_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
);
```

### SOS Screen (Child App)

```dart
import 'package:parental_control_app/features/notifications/presentation/pages/sos_emergency_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SOSEmergencyScreen()),
);
```

## Integration Points

### 1. Message Monitoring
Already integrated in `message_remote_datasource.dart` - automatically sends alerts when suspicious messages are detected.

### 2. Geofencing
Integrate in geofencing service:
```dart
final integrationService = NotificationIntegrationService();
await integrationService.onGeofencingEvent(
  parentId: parentId,
  childId: childId,
  zoneName: zoneName,
  eventType: 'exit', // or 'entry'
  latitude: position.latitude,
  longitude: position.longitude,
);
```

### 3. Screen Time
Integrate in app limits service:
```dart
final integrationService = NotificationIntegrationService();
await integrationService.onScreenTimeLimitReached(
  parentId: parentId,
  childId: childId,
  dailyLimitMinutes: 120,
  currentUsageMinutes: 120,
);
```

### 4. URL/App Blocking
Integrate in URL tracking service:
```dart
final integrationService = NotificationIntegrationService();
await integrationService.onAppWebsiteBlocked(
  parentId: parentId,
  childId: childId,
  blockedItem: 'facebook.com',
  blockType: 'website',
);
```

## Firebase Structure

```
parents/
  {parentId}/
    fcmToken: string
    notifications/
      {notificationId}/
        id: string
        parentId: string
        childId: string
        alertType: string
        title: string
        body: string
        data: object
        timestamp: timestamp
        isRead: boolean
        readAt: timestamp
        actionUrl: string
    children/
      {childId}/
        fcmToken: string
```

## Testing

1. **Test FCM Token**: Check if token is saved in Firestore
2. **Test Notifications**: Send test notification via Firebase Console
3. **Test Alerts**: Trigger different alert types and verify notifications

## Notes

- FCM tokens are automatically saved to Firestore when app initializes
- Notifications are saved to Firestore for history
- Local notifications are shown for foreground messages
- Background messages are handled automatically
- Cloud Functions recommended for production FCM sending (see `alert_sender_service.dart`)

## Next Steps

1. Implement Cloud Functions for FCM sending (recommended for production)
2. Add notification preferences/settings
3. Add notification categories and filtering
4. Implement notification actions (e.g., "View", "Dismiss", "Block")
5. Add notification sound customization
6. Implement notification grouping

