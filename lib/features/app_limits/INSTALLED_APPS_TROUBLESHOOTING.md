# Installed Apps Sync Troubleshooting Guide

## 🔍 Problem: Installed Apps Not Showing on Parent Device

Agar parent device par installed apps nahi dikh rahi, to yeh steps follow karein:

## ✅ Step 1: Check Child Device Initialization

### Child Device Par:
1. **App Restart Karein:**
   - Child device par app completely close karein
   - Phir dobara open karein
   - App initialization ke logs check karein

2. **Console Logs Check Karein:**
   ```
   ✅ [ChildAppInit] ========== INITIALIZING APP USAGE TRACKING ==========
   ✅ [ChildAppInit] Service initialized
   ✅ [RealTimeAppUsageService] Started real-time tracking
   🔄 [RealTimeAppUsageService] ========== SYNCING INSTALLED APPS ==========
   📱 Found X installed apps on device
   ✅ Successfully synced X apps to Firebase
   ```

3. **Agar Error Dikhe:**
   - Error message note karein
   - Stack trace check karein
   - Child ID aur Parent ID verify karein

## ✅ Step 2: Verify Firebase Data

### Firebase Console Mein:
1. **Path Check Karein:**
   ```
   parents/{parentId}/children/{childId}/installedApps/
   ```

2. **Documents Check Karein:**
   - Agar documents hain → Data store ho raha hai ✅
   - Agar documents nahi hain → Sync issue hai ❌

3. **Document Structure:**
   ```json
   {
     "id": "app_com.example.app",
     "packageName": "com.example.app",
     "appName": "App Name",
     "isSystemApp": false,
     "installTime": Timestamp,
     "detectedAt": Timestamp,
     ...
   }
   ```

## ✅ Step 3: Check Parent Device Fetch

### Parent Device Par:
1. **Console Logs Check Karein:**
   ```
   📱 [ParentDashboardFirebaseService] Fetching installed apps stream
   📱 [ParentDashboardFirebaseService] Installed apps snapshot received: X apps
   ✅ [ParentDashboardFirebaseService] Parsed X installed apps
   ```

2. **Agar "0 apps" Dikhe:**
   - Firebase mein data check karein (Step 2)
   - Child ID aur Parent ID verify karein
   - Network connection check karein

## 🔧 Common Issues & Solutions

### Issue 1: Service Not Starting
**Symptoms:**
- Console mein "Error starting tracking" dikhe
- Native service start nahi ho rahi

**Solution:**
- Android permissions check karein
- App restart karein
- Device restart karein

### Issue 2: No Apps Found on Device
**Symptoms:**
- Console mein "Found 0 installed apps on device" dikhe

**Solution:**
- `QUERY_ALL_PACKAGES` permission check karein
- AndroidManifest.xml mein permission verify karein
- App restart karein

### Issue 3: Firebase Sync Failing
**Symptoms:**
- Console mein "Error syncing installed apps" dikhe
- Firebase mein data nahi hai

**Solution:**
- Firebase connection check karein
- Firebase rules verify karein
- Child/Parent IDs verify karein

### Issue 4: Data Not Showing on Parent
**Symptoms:**
- Firebase mein data hai
- Parent device par nahi dikh raha

**Solution:**
- Parent device par app restart karein
- Network connection check karein
- Firebase stream listener check karein

## 📋 Testing Checklist

- [ ] Child device par app restart kiya
- [ ] Console logs check kiye (child device)
- [ ] Firebase Console mein data verify kiya
- [ ] Parent device par app restart kiya
- [ ] Console logs check kiye (parent device)
- [ ] "Installed" tab par refresh button try kiya
- [ ] Network connection verify kiya

## 🚀 Quick Fix Steps

1. **Child Device:**
   ```
   - App completely close karein
   - App dobara open karein
   - 10-15 seconds wait karein
   - Console logs check karein
   ```

2. **Parent Device:**
   ```
   - "Installed" tab open karein
   - Refresh button click karein
   - 5-10 seconds wait karein
   - Apps check karein
   ```

3. **Firebase Console:**
   ```
   - Path verify karein
   - Documents count check karein
   - Data structure verify karein
   ```

## 📞 Debug Information

Agar issue solve nahi ho raha, to yeh information share karein:

1. **Child Device Logs:**
   - Service initialization logs
   - Sync logs
   - Error messages (agar hui)

2. **Parent Device Logs:**
   - Firebase fetch logs
   - Stream listener logs
   - Error messages (agar hui)

3. **Firebase Console:**
   - Documents count
   - Sample document data
   - Path screenshot

4. **Device Info:**
   - Android version
   - App version
   - Device model

## ✅ Expected Behavior

1. **Child Device Start:**
   - Service immediately initialize hoti hai
   - Installed apps immediately sync hoti hain
   - Har 5 minutes automatic sync hoti hai

2. **Firebase:**
   - Data immediately store hota hai
   - Collection: `installedApps/`
   - Documents: `app_{packageName}`

3. **Parent Device:**
   - Real-time stream se data fetch hota hai
   - "Installed" tab par saari apps dikhti hain
   - Search, filter, sort sab kaam karta hai

