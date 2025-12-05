# Real-Time App Usage Tracking Setup Guide

## 📋 Overview

Yeh guide batata hai ke kaise real-time app usage tracking setup karein child device par.

## 🏗️ Architecture

### **Android Native Side:**
- `AppUsageTrackingService.kt` - Foreground service jo continuously app usage track karta hai
- Har 2 seconds mein foreground app check karta hai
- Har 30 seconds mein Flutter ko data sync karta hai

### **Flutter Side:**
- `RealTimeAppUsageService` - Native service se events receive karta hai
- `ChildDeviceSyncService` - Firebase ko data sync karta hai

## 🔧 Setup Steps

### Step 1: AndroidManifest.xml Update

Service already register ho chuki hai:
```xml
<service
    android:name=".AppUsageTrackingService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="dataSync" />
```

### Step 2: Child Device Initialization

Child device ke main app initialization mein:

```dart
import 'package:your_app/features/app_limits/data/services/real_time_app_usage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// In your app initialization (main.dart or app initialization)
final realTimeService = RealTimeAppUsageService();

// Get child and parent IDs
final childId = FirebaseAuth.instance.currentUser?.uid;
final parentId = // Get from child profile

// Initialize service
realTimeService.initialize(
  childId: childId!,
  parentId: parentId,
);

// Start real-time tracking
await realTimeService.startTracking();
```

### Step 3: App Lifecycle Management

App lifecycle ke saath service ko manage karein:

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final RealTimeAppUsageService _realTimeService = RealTimeAppUsageService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize and start tracking
    _initializeTracking();
  }
  
  Future<void> _initializeTracking() async {
    final childId = FirebaseAuth.instance.currentUser?.uid;
    final parentId = // Get parent ID
    
    if (childId != null && parentId != null) {
      _realTimeService.initialize(
        childId: childId,
        parentId: parentId,
      );
      await _realTimeService.startTracking();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App background - service continues running
    } else if (state == AppLifecycleState.resumed) {
      // App resumed - ensure tracking is active
      _realTimeService.startTracking();
    } else if (state == AppLifecycleState.detached) {
      // App closed - stop tracking
      _realTimeService.stopTracking();
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realTimeService.dispose();
    super.dispose();
  }
}
```

## 📊 How It Works

### **Real-Time Flow:**

1. **Android Service** (AppUsageTrackingService):
   - Har 2 seconds mein foreground app check karta hai
   - App change detect karta hai
   - Usage time calculate karta hai
   - Har 30 seconds mein Flutter ko data send karta hai

2. **Flutter Service** (RealTimeAppUsageService):
   - Native service se events receive karta hai
   - App usage data update karta hai
   - Firebase ko sync karta hai

3. **Firebase Sync**:
   - App usage data Firebase mein save hota hai
   - Screen time update hota hai
   - Parent real-time dekh sakta hai

## 🔔 Events

### **onAppChanged**
Jab bhi app change ho:
```dart
{
  "packageName": "com.example.app",
  "appName": "Example App",
  "isSystemApp": false,
  "timestamp": 1234567890
}
```

### **onUsageStatsUpdated**
Har 30 seconds mein:
```dart
{
  "appUsageList": [
    {
      "packageName": "com.example.app",
      "appName": "Example App",
      "usageDuration": 45, // minutes
      "launchCount": 10,
      "lastUsed": 1234567890,
      "isSystemApp": false
    }
  ],
  "totalScreenTime": 120, // minutes
  "timestamp": 1234567890
}
```

## ✅ Features

1. **Real-Time Tracking**: Continuous monitoring, har 2 seconds check
2. **Foreground Service**: Background mein bhi kaam karta hai
3. **Auto Sync**: Har 30 seconds Firebase ko sync
4. **App Launch Detection**: Launch count automatically track
5. **Screen Time Calculation**: Total screen time real-time calculate

## 🛠️ Troubleshooting

### Service start nahi ho rahi?
- Check ke `FOREGROUND_SERVICE` permission hai
- Check ke Usage Stats permission granted hai
- Logs check karein: `adb logcat | grep AppUsageTrackingService`

### Data sync nahi ho raha?
- Check ke Firebase initialized hai
- Check ke childId aur parentId sahi hain
- Network connection check karein

### App change detect nahi ho raha?
- Usage Stats permission check karein
- Service running hai ya nahi check karein
- Logs check karein

## 📝 Notes

- Service foreground service hai, isliye notification show hogi
- Battery optimization disable karein for better tracking
- Service boot time par auto-start kar sakti hai (BootReceiver use karein)

