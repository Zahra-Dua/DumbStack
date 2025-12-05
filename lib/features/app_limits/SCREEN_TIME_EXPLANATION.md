# Screen Time Explanation

## 📱 Screen Time Kya Hai?

**Screen Time** = Total time jab phone ka screen **ON/ACTIVE** tha

### Example:
Agar child ne:
- WhatsApp use kiya: 30 minutes
- YouTube use kiya: 45 minutes  
- Games khele: 20 minutes
- Browser use kiya: 15 minutes

**Total Screen Time = 30 + 45 + 20 + 15 = 110 minutes (1 hour 50 minutes)**

## 🔍 Kaise Calculate Hota Hai?

### **Method 1: Sum of All App Usage Times** (Current Implementation)
```
Screen Time = Sum of all user apps usage time
```

**Formula:**
```
Screen Time = App1_Usage + App2_Usage + App3_Usage + ... + AppN_Usage
```

**Example:**
- WhatsApp: 30 min
- YouTube: 45 min
- Games: 20 min
- **Total Screen Time = 95 minutes**

### **Method 2: Device Level Tracking** (Alternative)
- Direct device se screen on/off time track karein
- Lekin yeh method complex hai aur har device par different ho sakta hai

## ✅ Current Implementation

### **Android Native Side:**
```kotlin
// AppUsageTrackingService.kt
val totalScreenTime = appUsageMap.values
    .filter { !it.isSystemApp } // System apps exclude
    .sumOf { it.totalUsageTime } / 1000 / 60 // milliseconds to minutes
```

### **Flutter Side:**
```dart
// RealTimeAppUsageService
final userAppsTotalTime = _appUsageMap.values
    .where((app) => !app.isSystemApp)
    .fold<int>(0, (sum, app) => sum + app.usageDurationMinutes);
```

### **Firebase:**
```
parents/{parentId}/children/{childId}/screenTime/
└── screen_time_YYYY-MM-DD/
    ├── totalScreenTimeMinutes: 95
    ├── totalScreenTimeHours: "1.58"
    └── date: Timestamp
```

## 📊 Screen Time vs App Usage

| Feature | Screen Time | App Usage |
|---------|-------------|-----------|
| **Definition** | Total time screen was ON | Individual app usage time |
| **Calculation** | Sum of all apps | Per app tracking |
| **Example** | 95 minutes total | WhatsApp: 30min, YouTube: 45min |
| **Use Case** | Daily limit enforcement | App-specific limits |

## 🎯 Key Points

1. **Screen Time = Sum of All Apps**
   - Har app ka usage time add karke total screen time calculate hota hai

2. **System Apps Excluded**
   - System apps (like Settings, System UI) exclude kiye jate hain
   - Sirf user-installed apps count hote hain

3. **Real-Time Calculation**
   - Har 30 seconds mein recalculate hota hai
   - Firebase mein save hota hai

4. **Daily Basis**
   - Har din ka screen time separately track hota hai
   - Date-wise Firebase mein store hota hai

## 🔧 How It Works

### **Step 1: Track App Usage**
```
Child opens WhatsApp → Track 30 minutes
Child opens YouTube → Track 45 minutes
```

### **Step 2: Calculate Screen Time**
```
Screen Time = 30 + 45 = 75 minutes
```

### **Step 3: Save to Firebase**
```
Firebase: screenTime/screen_time_2024-01-15/
  totalScreenTimeMinutes: 75
```

### **Step 4: Parent Sees**
```
Parent Dashboard: "Total Screen Time: 75 minutes"
```

## ✅ Current Status

- ✅ Screen time properly calculate ho raha hai
- ✅ System apps exclude ho rahe hain
- ✅ Real-time updates ho rahe hain
- ✅ Firebase mein save ho raha hai
- ✅ Parent ko dikh raha hai

## 📝 Notes

- Screen time = **Total phone usage time** (not individual app time)
- System apps exclude hote hain (accurate user screen time)
- Daily basis par reset hota hai
- Real-time calculate aur sync hota hai

