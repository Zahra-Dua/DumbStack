# 🔍 Troubleshooting Guide - App Usage & Installed Apps Not Showing

## ✅ Step-by-Step Debugging

### **1. Check Child Device Initialization**

#### **A. Verify Child App is Running:**
- Open child device app
- Check console logs for:
  ```
  🔄 [ChildAppInit] ========== INITIALIZING APP USAGE TRACKING ==========
  ✅ [ChildAppInit] Service initialized
  🔄 [RealTimeAppUsageService] Starting installed apps sync FIRST...
  ```

#### **B. Check SharedPreferences:**
- Verify `parent_uid` and `child_uid` are saved
- Add this debug code in `child_app_main_screen.dart`:
  ```dart
  final prefs = await SharedPreferences.getInstance();
  print('🔍 Parent ID: ${prefs.getString('parent_uid')}');
  print('🔍 Child ID: ${prefs.getString('child_uid')}');
  ```

### **2. Check Installed Apps Sync**

#### **A. Look for these logs:**
```
📱 [AppListService] Getting all installed apps using device_apps package...
📱 [AppListService] Found X installed apps
🔄 [RealTimeAppUsageService] ========== SYNCING INSTALLED APPS ==========
✅ [InstalledAppsFirebaseService] Successfully synced X apps to Firebase
```

#### **B. If logs are missing:**
- Service might not be starting
- Check if `_startInstalledAppsSync()` is being called
- Verify `device_apps` package permissions

### **3. Check Firebase Data**

#### **A. Firebase Console:**
1. Go to Firebase Console
2. Navigate to: `parents/{parentId}/children/{childId}/installedApps/`
3. Check if documents exist
4. Verify document structure matches `InstalledAppFirebase` model

#### **B. Firebase Console for App Usage:**
1. Navigate to: `parents/{parentId}/children/{childId}/appUsage/`
2. Check if documents exist
3. Verify `usageDuration`, `launchCount`, `lastUsed` fields

### **4. Check Parent Dashboard**

#### **A. Verify Stream is Listening:**
- Check console for:
  ```
  📱 [ParentDashboardFirebaseService] Fetching installed apps stream
  📱 [ParentDashboardFirebaseService] Installed apps snapshot received: X apps
  ```

#### **B. Check BLoC State:**
- Verify `ParentDashboardLoaded` state is emitted
- Check `installedApps` list is not empty

### **5. Common Issues & Fixes**

#### **Issue 1: Service Not Starting**
**Symptoms:** No logs about service initialization
**Fix:**
- Ensure `ChildAppMainScreen` is shown on child device
- Check `initializeChildApp()` is called
- Verify `parent_uid` and `child_uid` exist in SharedPreferences

#### **Issue 2: Installed Apps Not Syncing**
**Symptoms:** Logs show "Getting installed apps" but no Firebase sync
**Fix:**
- Check `device_apps` package permissions
- Verify `QUERY_ALL_PACKAGES` permission in AndroidManifest
- Check Firebase connection

#### **Issue 3: Firebase Collection Empty**
**Symptoms:** Logs show sync success but Firebase is empty
**Fix:**
- Check Firebase rules allow write
- Verify `childId` and `parentId` are correct
- Check batch commit is successful

#### **Issue 4: Parent Dashboard Not Showing Data**
**Symptoms:** Firebase has data but parent app shows empty
**Fix:**
- Verify `childId` and `parentId` match
- Check StreamBuilder is listening
- Verify BLoC is emitting correct state

## 🛠️ Manual Testing Steps

### **Step 1: Test Installed Apps Sync (Child Device)**
```dart
// Add this button in child app for testing
ElevatedButton(
  onPressed: () async {
    final service = RealTimeAppUsageService();
    service.initialize(
      childId: 'YOUR_CHILD_ID',
      parentId: 'YOUR_PARENT_ID',
    );
    await service.syncInstalledAppsNow();
  },
  child: Text('Sync Installed Apps Now'),
)
```

### **Step 2: Test Firebase Read (Parent Device)**
```dart
// Add this in parent dashboard for testing
ElevatedButton(
  onPressed: () async {
    final service = ParentDashboardFirebaseService();
    final apps = await service.getInstalledAppsStream(
      childId: 'YOUR_CHILD_ID',
      parentId: 'YOUR_PARENT_ID',
    ).first;
    print('📱 Found ${apps.length} installed apps');
  },
  child: Text('Test Firebase Read'),
)
```

### **Step 3: Check Firebase Rules**
```javascript
// Firebase Firestore Rules
match /parents/{parentId}/children/{childId}/installedApps/{appId} {
  allow read, write: if request.auth != null;
}
```

## 📝 Debug Checklist

- [ ] Child app is running
- [ ] `parent_uid` and `child_uid` exist in SharedPreferences
- [ ] `ChildAppInitializationService.initializeChildApp()` is called
- [ ] `RealTimeAppUsageService.startTracking()` is called
- [ ] `_startInstalledAppsSync()` is called
- [ ] `device_apps` package returns apps
- [ ] Firebase batch commit succeeds
- [ ] Firebase collection has documents
- [ ] Parent dashboard BLoC receives data
- [ ] UI displays data correctly

## 🚨 Emergency Fixes

### **Fix 1: Force Restart Service**
```dart
// In child app, add this:
await _realTimeAppUsageService?.stopTracking();
await _realTimeAppUsageService?.dispose();
_realTimeAppUsageService = RealTimeAppUsageService();
_realTimeAppUsageService!.initialize(childId: childId, parentId: parentId);
await _realTimeAppUsageService!.startTracking();
```

### **Fix 2: Manual Firebase Sync**
```dart
// Direct Firebase write for testing
final apps = await AppListService().getInstalledApps();
await InstalledAppsFirebaseService().syncInstalledApps(
  apps: apps,
  childId: childId,
  parentId: parentId,
);
```

### **Fix 3: Clear and Re-sync**
```dart
// Clear Firebase collection and re-sync
final batch = FirebaseFirestore.instance.batch();
final snapshot = await FirebaseFirestore.instance
    .collection('parents')
    .doc(parentId)
    .collection('children')
    .doc(childId)
    .collection('installedApps')
    .get();
    
for (var doc in snapshot.docs) {
  batch.delete(doc.reference);
}
await batch.commit();

// Then re-sync
await service.syncInstalledAppsNow();
```

## 📞 Next Steps

1. **Check Console Logs First** - Most issues show in logs
2. **Verify Firebase Data** - Confirm data is actually being saved
3. **Test Parent Dashboard** - Ensure reading works
4. **Check Permissions** - Android permissions might be blocking
5. **Verify IDs** - `childId` and `parentId` must match exactly

