# Parent Dashboard - Firebase Integration

This module provides a complete parent dashboard system that fetches real-time data from Firebase to display child's activity including URL tracking and app usage.

## Features

### Parent Side
- **Real-time Dashboard**: View child's activity in real-time
- **URL Tracking**: See all visited websites with blocking controls
- **App Usage**: Monitor app usage with time limits and risk scores
- **Digital Wellbeing**: Screen time analytics and daily/weekly summaries
- **VPN Control**: Block websites at system level
- **Settings**: Configure limits and notifications

### Child Side
- **Automatic Data Upload**: All tracking data automatically uploads to Firebase
- **Background Sync**: Periodic data synchronization
- **Non-intrusive**: Doesn't interfere with child's device usage

## Firebase Structure

```
parents (collection)
  - {parentId} (document)
    - children (collection)
      - {childId} (document)
        - visitedUrls (subcollection)
          - {urlId} (document)
            - url: string
            - title: string
            - visitedAt: timestamp
            - packageName: string
            - isBlocked: boolean
            - browserName: string
            - metadata: object
        - appUsage (subcollection)
          - {appId} (document)
            - packageName: string
            - appName: string
            - usageDuration: number (minutes)
            - launchCount: number
            - lastUsed: timestamp
            - appIcon: string
            - isSystemApp: boolean
            - riskScore: number
```

## Integration Steps

### 1. Add Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  flutter_bloc: ^8.1.3
```

### 2. Child Side Integration

In your existing child tracking code, add Firebase upload:

```dart
// In your URL tracking service
import 'package:content_control/features/url_tracking/data/services/child_url_tracking_service.dart';

class YourExistingUrlTrackingService {
  final ChildUrlTrackingService _firebaseService = ChildUrlTrackingService();

  // When URL is detected
  Future<void> onUrlDetected(String url, String title, String packageName) async {
    // Your existing logic...
    
    // Upload to Firebase
    await _firebaseService.uploadVisitedUrl(
      url: url,
      title: title,
      packageName: packageName,
      childId: getCurrentChildId(),
      parentId: getParentId(),
    );
  }
}
```

### 3. Parent Side Integration

```dart
// In your main app
import 'package:content_control/features/parent_dashboard/presentation/pages/parent_home_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ParentHomeScreen(), // Your parent dashboard
    );
  }
}
```

### 4. VPN Control (Parent Side Only)

The VPN control is implemented on the parent side only. Child side shows only status:

```dart
// Parent can start/stop VPN blocking
void _startVpnBlocking() async {
  // Implementation for VPN blocking
  // This blocks URLs at system level
}
```

## Usage

### Parent Dashboard Features

1. **Today Tab**: Shows today's activity summary
2. **Week Tab**: Shows weekly analytics with charts
3. **All Apps Tab**: Complete list of all apps with usage details

### Real-time Updates

All data is fetched from Firebase in real-time using streams:

```dart
// URLs are updated in real-time
Stream<List<VisitedUrlFirebase>> getVisitedUrlsStream() {
  return _firestore
      .collection('parents')
      .doc(parentId)
      .collection('children')
      .doc(childId)
      .collection('visitedUrls')
      .orderBy('visitedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => VisitedUrlFirebase.fromJson(doc.data()))
          .toList());
}
```

### Data Flow

1. **Child visits website** → Native tracking detects URL
2. **URL data** → Uploaded to Firebase `visitedUrls` subcollection
3. **Parent opens dashboard** → Fetches data from Firebase
4. **Real-time updates** → Parent sees new URLs immediately
5. **Parent blocks URL** → Updates Firebase, child's device respects block

## Customization

### Adding New Data Fields

1. Update the Firebase models (`visited_url_firebase.dart`, `app_usage_firebase.dart`)
2. Update the upload services
3. Update the UI widgets to display new fields

### Styling

All UI components are customizable. The design matches your provided screenshots with:
- Purple/blue color scheme
- Card-based layout
- Real-time data display
- Intuitive navigation

## Security

- All data is stored securely in Firebase
- Parent-child relationships are properly managed
- VPN blocking is controlled only by parents
- Child data is not accessible to other parents

## Performance

- Efficient Firebase queries with proper indexing
- Real-time updates without excessive API calls
- Background sync for child side
- Optimized UI rendering

## Troubleshooting

### Common Issues

1. **Data not appearing**: Check Firebase rules and authentication
2. **Real-time updates not working**: Verify stream subscriptions
3. **VPN not working**: Check device permissions and implementation
4. **Upload failures**: Check network connectivity and Firebase configuration

### Debug Mode

Enable debug logging to see data flow:
```dart
// In your services
print('✅ URL uploaded to Firebase: $url');
print('❌ Error uploading URL: $e');
```

## Support

For issues or questions:
1. Check Firebase console for data
2. Verify authentication setup
3. Check network connectivity
4. Review error logs in console
