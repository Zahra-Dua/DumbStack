# App Limits Firebase Integration Guide

## 📋 Overview

Yeh guide batata hai ke kaise app limits module ko Firebase ke saath integrate karein for parent-child real-time data sync.

## 🏗️ Architecture

### **Child Device (Child Phone)**
- `ChildDeviceSyncService` - Child device se Firebase ko data sync karta hai
- `ChildLimitsService` - Parent ke set kiye gaye limits Firebase se fetch karta hai
- Data sync hota hai: App Usage, Screen Time, Installed Apps

### **Parent Device (Parent Phone)**
- `ParentChildDataService` - Child ka data Firebase se fetch karta hai (real-time)
- `AppLimitsFirebaseService` - App limits set/clear karta hai
- Parent child ka data dekh sakta hai: Total screen time, App count, App usage (sorted high to low)

## 🔥 Firebase Collections Structure

```
parents/
├── {parentId}/
│   └── children/
│       └── {childId}/
│           ├── appUsage/          # Child's app usage data
│           │   └── {appId}/
│           ├── screenTime/        # Daily screen time
│           │   └── screen_time_YYYY-MM-DD/
│           ├── installedApps/     # Installed apps list
│           │   └── app_{packageName}/
│           └── appLimits/         # App limits set by parent
│               └── limit_{packageName}/
```

## 📱 Child Device Integration

### Step 1: Initialize Sync Service

Child device ke main app initialization mein:

```dart
import 'package:your_app/features/app_limits/data/services/child_device_sync_service.dart';
import 'package:your_app/features/app_limits/data/services/child_limits_service.dart';

// In your app initialization
final childSyncService = ChildDeviceSyncService();
final childLimitsService = ChildLimitsService();

// Get child and parent IDs (from Firebase Auth or your auth system)
final childId = FirebaseAuth.instance.currentUser?.uid;
final parentId = // Get from child profile or auth

// Initialize services
childSyncService.initialize(childId: childId!, parentId: parentId);
childLimitsService.initialize(childId: childId!, parentId: parentId);

// Start periodic sync (every 30 seconds)
childSyncService.startPeriodicSync();
```

### Step 2: Sync App Usage

Jab bhi app usage change ho, Firebase ko sync karein:

```dart
// In your UsageStatsService or wherever app usage is tracked
await childSyncService.syncAppUsage(
  packageName: 'com.example.app',
  appName: 'Example App',
  usageDurationMinutes: 45,
  launchCount: 10,
  lastUsed: DateTime.now(),
  appIcon: 'path/to/icon',
  isSystemApp: false,
);
```

### Step 3: Sync Screen Time

Daily screen time sync karein:

```dart
// Calculate total screen time from all apps
final totalMinutes = // Calculate from app usage

await childSyncService.syncScreenTime(
  totalScreenTimeMinutes: totalMinutes,
  date: DateTime.now(),
);
```

### Step 4: Sync Installed Apps

Installed apps list sync karein:

```dart
// Get installed apps list
final installedApps = await appListService.getInstalledApps();

await childSyncService.syncInstalledApps(apps: installedApps);
```

### Step 5: Show Limits to Child

Child ko limits dikhane ke liye:

```dart
// Get global screen time limit
final globalLimit = await childLimitsService.getGlobalScreenTimeLimit();
if (globalLimit != null) {
  final limitMinutes = globalLimit['dailyLimitMinutes'] as int;
  // Show to child: "Your daily limit: ${limitMinutes} minutes"
}

// Get app limits stream (real-time)
childLimitsService.getAppLimitsStream().listen((limits) {
  // Update UI with limits
  for (var limit in limits) {
    final packageName = limit['packageName'];
    final limitMinutes = limit['dailyLimitMinutes'];
    // Show limit for each app
  }
});

// Get today's screen time
final todayScreenTime = await childLimitsService.getTodayScreenTime();
// Show: "Today's usage: ${todayScreenTime} minutes"
```

## 👨‍👩‍👧 Parent Device Integration

### Step 1: Initialize Parent Service

```dart
import 'package:your_app/features/app_limits/data/services/parent_child_data_service.dart';
import 'package:your_app/features/app_limits/data/services/app_limits_firebase_service.dart';

final parentDataService = ParentChildDataService();
final limitsService = AppLimitsFirebaseService();

// Get parent and child IDs
final parentId = FirebaseAuth.instance.currentUser?.uid;
final childId = // Selected child ID
```

### Step 2: Show Child's App Usage (Sorted High to Low)

```dart
// Real-time stream
parentDataService.getChildAppUsageStream(
  childId: childId,
  parentId: parentId,
).listen((apps) {
  // Apps are already sorted by usageDuration (high to low)
  // Update UI
  for (var app in apps) {
    print('${app.appName}: ${app.usageDuration} minutes');
  }
});

// Or get once
final apps = await parentDataService.getChildTodayAppUsage(
  childId: childId,
  parentId: parentId,
);
// Apps are sorted high to low
```

### Step 3: Show Child's Screen Time

```dart
// Real-time stream
parentDataService.getChildScreenTimeStream(
  childId: childId,
  parentId: parentId,
).listen((minutes) {
  // Update UI: "Total screen time: ${minutes} minutes"
});

// Or get once
final minutes = await parentDataService.getChildTodayScreenTime(
  childId: childId,
  parentId: parentId,
);
```

### Step 4: Show Installed Apps Count

```dart
// Real-time stream
parentDataService.getChildInstalledAppsStream(
  childId: childId,
  parentId: parentId,
).listen((apps) {
  final count = apps.length;
  // Update UI: "Total apps: $count"
});

// Or get count once
final count = await parentDataService.getChildInstalledAppsCount(
  childId: childId,
  parentId: parentId,
);
```

### Step 5: Set App Limits

```dart
// Set individual app limit
await limitsService.setAppLimit(
  childId: childId,
  parentId: parentId,
  packageName: 'com.example.app',
  appName: 'Example App',
  dailyLimitMinutes: 60, // 1 hour per day
);

// Set global screen time limit
await limitsService.setGlobalScreenTimeLimit(
  childId: childId,
  parentId: parentId,
  dailyLimitMinutes: 120, // 2 hours per day
);
```

### Step 6: Clear Limits

```dart
// Clear app limit
await limitsService.clearAppLimit(
  childId: childId,
  parentId: parentId,
  packageName: 'com.example.app',
);

// Clear global limit
await limitsService.clearGlobalScreenTimeLimit(
  childId: childId,
  parentId: parentId,
);
```

## 🎨 UI Integration Example

### Parent Side - Child App Usage Screen

```dart
StreamBuilder<List<AppUsageFirebase>>(
  stream: parentDataService.getChildAppUsageStream(
    childId: childId,
    parentId: parentId,
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    
    final apps = snapshot.data!;
    
    return Column(
      children: [
        // Total screen time
        StreamBuilder<int>(
          stream: parentDataService.getChildScreenTimeStream(
            childId: childId,
            parentId: parentId,
          ),
          builder: (context, timeSnapshot) {
            final minutes = timeSnapshot.data ?? 0;
            return Text('Total Screen Time: ${minutes} minutes');
          },
        ),
        
        // Apps count
        StreamBuilder<List<InstalledAppFirebase>>(
          stream: parentDataService.getChildInstalledAppsStream(
            childId: childId,
            parentId: parentId,
          ),
          builder: (context, appsSnapshot) {
            final count = appsSnapshot.data?.length ?? 0;
            return Text('Total Apps: $count');
          },
        ),
        
        // Apps list (sorted high to low)
        Expanded(
          child: ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return ListTile(
                title: Text(app.appName),
                subtitle: Text('${app.usageDuration} minutes'),
                trailing: IconButton(
                  icon: Icon(Icons.timer),
                  onPressed: () {
                    // Show set limit dialog
                    _showSetLimitDialog(app);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  },
)
```

### Child Side - Limits Display

```dart
StreamBuilder<Map<String, dynamic>?>(
  stream: childLimitsService.getGlobalScreenTimeLimitStream(),
  builder: (context, snapshot) {
    final limit = snapshot.data;
    if (limit != null) {
      final limitMinutes = limit['dailyLimitMinutes'] as int;
      return Text('Daily Limit: $limitMinutes minutes');
    }
    return Text('No limit set');
  },
)

StreamBuilder<int>(
  stream: childLimitsService.getTodayScreenTimeStream(),
  builder: (context, snapshot) {
    final minutes = snapshot.data ?? 0;
    return Text('Today: $minutes minutes');
  },
)
```

## ✅ Key Features

1. **Real-time Updates**: Sab kuch real-time hai - parent child ka data instantly dekh sakta hai
2. **Sorted by Usage**: Apps automatically sorted hain usage time ke according (high to low)
3. **Firebase Collections**: Sab data Firebase mein maintain hota hai
4. **Parent-Child Sync**: Child device se data Firebase ko sync hota hai, parent Firebase se fetch karta hai

## 🔧 Next Steps

1. Child device ke `UsageStatsService` mein sync calls add karein
2. Parent side UI update karein to use `ParentChildDataService`
3. Child side UI update karein to show limits from `ChildLimitsService`
4. Test karein ke sab kuch real-time kaam kar raha hai

## 📝 Notes

- Child device har 30 seconds mein automatically sync karta hai
- Parent side real-time streams use karta hai, so instant updates
- App limits Firebase mein store hote hain, child device real-time fetch karta hai
- Screen time daily basis par calculate hota hai

