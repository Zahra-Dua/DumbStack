# Installed Apps Sync Summary

## ✅ Complete Setup

### **What's Working:**

1. **Installed Apps Tab** (`Installed` tab in Parent Dashboard)
   - Shows **ALL installed apps** (used + unused)
   - Data from: `parents/{parentId}/children/{childId}/installedApps/`
   - Includes: User apps, System apps, New installations
   - Features: Search, Filter (All/User/System/New), App details

2. **App Usage Tab** (`All Apps` tab in Parent Dashboard)
   - Shows **ONLY used apps** (with usage time)
   - Data from: `parents/{parentId}/children/{childId}/appUsage/`
   - Shows: App name, Usage time, Launch count, Last used
   - Sorted by: Usage time (highest to lowest)

## 🔄 How It Works

### **Child Device Side:**

1. **Real-Time App Usage Service** (`real_time_app_usage_service.dart`)
   - Tracks app usage in real-time (every 30 seconds)
   - Syncs used apps to Firebase: `appUsage` collection
   - **NEW:** Also syncs ALL installed apps every 5 minutes: `installedApps` collection

2. **Periodic Sync:**
   - **App Usage:** Every 30 seconds (only used apps)
   - **Installed Apps:** Every 5 minutes (ALL apps, used + unused)

### **Parent Device Side:**

1. **Parent Dashboard** (`parent_dashboard_screen.dart`)
   - **"All Apps" Tab:** Shows used apps from `appUsage` collection
   - **"Installed" Tab:** Shows all apps from `installedApps` collection

2. **Data Sources:**
   - `getAppUsageStream()` → Used apps only
   - `getInstalledAppsStream()` → All installed apps

## 📊 Firebase Collections

### **1. App Usage Collection** (Used Apps Only)
```
parents/{parentId}/children/{childId}/appUsage/
└── {packageName}/
    ├── packageName: "com.whatsapp"
    ├── appName: "WhatsApp"
    ├── usageDuration: 30 (minutes)
    ├── launchCount: 5
    ├── lastUsed: Timestamp
    └── isSystemApp: false
```

### **2. Installed Apps Collection** (ALL Apps)
```
parents/{parentId}/children/{childId}/installedApps/
└── app_{packageName}/
    ├── packageName: "com.whatsapp"
    ├── appName: "WhatsApp"
    ├── versionName: "2.23.1"
    ├── versionCode: 123
    ├── isSystemApp: false
    ├── installTime: Timestamp
    ├── lastUpdateTime: Timestamp
    ├── detectedAt: Timestamp
    ├── isNewInstallation: false
    └── createdAt: Timestamp
```

## 🎯 Key Points

1. **Installed Apps Tab:**
   - Shows **ALL** apps installed on child's device
   - Includes apps that were never used
   - Updated every 5 minutes

2. **App Usage Tab:**
   - Shows **ONLY** apps that have been used
   - Shows usage time, launch count, last used
   - Updated every 30 seconds

3. **Real-Time Sync:**
   - App usage: Real-time (30 seconds)
   - Installed apps: Periodic (5 minutes)

## ✅ Verification

- ✅ Installed apps tab shows ALL installed apps (used + unused)
- ✅ App usage tab shows ONLY used apps with usage time
- ✅ Installed apps sync every 5 minutes from child device
- ✅ App usage sync every 30 seconds from child device
- ✅ Both collections maintained separately in Firebase

## 📝 Notes

- If an app is installed but never used:
  - ✅ Will show in "Installed" tab
  - ❌ Will NOT show in "All Apps" tab (until used)

- If an app is used:
  - ✅ Will show in "Installed" tab
  - ✅ Will show in "All Apps" tab (with usage time)

