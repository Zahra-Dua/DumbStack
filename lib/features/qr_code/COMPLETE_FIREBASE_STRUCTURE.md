# Complete Firebase Structure - Parental Control App

## 🏗️ **Complete Firebase Database Structure**

### **1. Parents Collection**
```
parents/
├── {parentId}/
│   ├── parentId: "parent_123"
│   ├── name: "John Doe"
│   ├── email: "john@example.com"
│   ├── userType: "parent"
│   ├── avatarUrl: "https://example.com/avatar.jpg"
│   ├── createdAt: Timestamp
│   ├── updatedAt: Timestamp
│   ├── childIds: ["child_1", "child_2", "child_3"]
│   └── children/ (subcollection)
```

### **2. Children Subcollection (Under Each Parent)**
```
parents/{parentId}/children/
├── {childId}/
│   ├── childId: "child_1"
│   ├── parentId: "parent_123"
│   ├── name: "Alice Doe"
│   ├── email: "alice@example.com"
│   ├── userType: "child"
│   ├── avatarUrl: "https://example.com/alice.jpg"
│   ├── createdAt: Timestamp
│   ├── updatedAt: Timestamp
│   ├── deviceInfo: {
│   │   ├── deviceId: "device_123"
│   │   ├── deviceName: "iPhone 13"
│   │   ├── osVersion: "iOS 15.0"
│   │   ├── appVersion: "1.0.0"
│   │   └── lastSeen: Timestamp
│   │ }
│   ├── isActive: true
│   ├── restrictions: ["app_blocking", "time_limits", "content_filtering"]
│   │
│   │ // 🗺️ LOCATION TRACKING FIELDS
│   ├── currentLatitude: 37.7749
│   ├── currentLongitude: -122.4194
│   ├── currentAddress: "123 Main St, San Francisco, CA"
│   ├── locationAccuracy: 10.5
│   ├── lastLocationUpdate: Timestamp
│   ├── isLocationTrackingEnabled: true
│   ├── currentLocationStatus: "online" // 'online', 'offline', 'unknown'
│   ├── locationHistory: [
│   │   {
│   │     "latitude": 37.7749,
│   │     "longitude": -122.4194,
│   │     "address": "123 Main St, San Francisco, CA",
│   │     "accuracy": 10.5,
│   │     "timestamp": "2024-01-01T12:00:00Z"
│   │   },
│   │   {
│   │     "latitude": 37.7849,
│   │     "longitude": -122.4094,
│   │     "address": "456 Oak Ave, San Francisco, CA",
│   │     "accuracy": 8.2,
│   │     "timestamp": "2024-01-01T11:30:00Z"
│   │   }
│   │   // ... more location history (last 50 entries)
│   │ ]
│   │
│   └── messages/ (subcollection)
```

### **3. Messages Subcollection (Under Each Child)**
```
parents/{parentId}/children/{childId}/messages/
├── {messageId}/
│   ├── messageId: "msg_1234567890"
│   ├── childId: "child_1"
│   ├── parentId: "parent_123"
│   ├── senderId: "child_1" // or "parent_123"
│   ├── senderType: "child" // or "parent"
│   ├── content: "Hello, I'm at school"
│   ├── messageType: "text" // 'text', 'sms', 'call_log', 'location', 'app_usage'
│   ├── metadata: {
│   │   // For SMS messages
│   │   "phoneNumber": "+1234567890",
│   │   "smsType": "received", // 'sent', 'received'
│   │   "smsTime": Timestamp,
│   │   
│   │   // For Location messages
│   │   "latitude": 37.7749,
│   │   "longitude": -122.4194,
│   │   "address": "123 Main St, San Francisco, CA",
│   │   "accuracy": 10.5,
│   │   
│   │   // For Call Log messages
│   │   "phoneNumber": "+1234567890",
│   │   "callType": "outgoing", // 'incoming', 'outgoing', 'missed'
│   │   "duration": 120, // in seconds
│   │   "callTime": Timestamp,
│   │   
│   │   // For App Usage messages
│   │   "appName": "Instagram",
│   │   "packageName": "com.instagram.android",
│   │   "usageTime": 1800, // in seconds
│   │   "sessionStart": Timestamp,
│   │   "sessionEnd": Timestamp
│   │ }
│   ├── isRead: false
│   ├── isBlocked: false
│   ├── timestamp: Timestamp
│   ├── readAt: null // Timestamp when read
│   ├── replyToMessageId: null // For replies
│   ├── attachments: [] // For file attachments
│   │
│   │ // 📱 SMS ANALYSIS FIELDS (for SMS messages only)
│   ├── flag: 0 // 0=Normal, 1=Spam, 2=Suspicious, 3=Blocked
│   ├── toxScore: 0.2 // 0.0-1.0 toxicity score
│   └── toxLabel: "safe" // 'safe', 'moderate', 'high', 'very_high'
```

## 📊 **Complete Data Flow**

### **1. Parent Creates Account**
```json
{
  "parentId": "parent_123",
  "name": "John Doe",
  "email": "john@example.com",
  "userType": "parent",
  "childIds": [],
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### **2. Parent Adds Child**
```json
{
  "childId": "child_1",
  "parentId": "parent_123",
  "name": "Alice Doe",
  "email": "alice@example.com",
  "userType": "child",
  "isLocationTrackingEnabled": true,
  "currentLocationStatus": "unknown",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### **3. Child Location Update**
```json
{
  "currentLatitude": 37.7749,
  "currentLongitude": -122.4194,
  "currentAddress": "123 Main St, San Francisco, CA",
  "locationAccuracy": 10.5,
  "lastLocationUpdate": "2024-01-01T12:00:00Z",
  "currentLocationStatus": "online",
  "locationHistory": [
    {
      "latitude": 37.7749,
      "longitude": -122.4194,
      "address": "123 Main St, San Francisco, CA",
      "accuracy": 10.5,
      "timestamp": "2024-01-01T12:00:00Z"
    }
  ]
}
```

### **4. SMS Message with Analysis**
```json
{
  "messageId": "msg_1234567890",
  "childId": "child_1",
  "parentId": "parent_123",
  "senderId": "child_1",
  "senderType": "child",
  "content": "Hey, I'm going to the mall with friends",
  "messageType": "sms",
  "metadata": {
    "phoneNumber": "+1234567890",
    "smsType": "sent",
    "smsTime": "2024-01-01T12:00:00Z"
  },
  "flag": 0,
  "toxScore": 0.1,
  "toxLabel": "safe",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### **5. Location Message**
```json
{
  "messageId": "loc_1234567890",
  "childId": "child_1",
  "parentId": "parent_123",
  "senderId": "child_1",
  "senderType": "child",
  "content": "Location shared",
  "messageType": "location",
  "metadata": {
    "latitude": 37.7749,
    "longitude": -122.4194,
    "address": "123 Main St, San Francisco, CA",
    "accuracy": 10.5
  },
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 🔄 **Real-time Updates**

### **Location Tracking Flow:**
1. **Child device** sends location update
2. **LocationTrackingService** processes the update
3. **ChildModel** is updated with new location
4. **Firebase** stores the updated child data
5. **Location message** is created in messages subcollection
6. **Parent UI** receives real-time updates

### **SMS Analysis Flow:**
1. **SMS received** on child device
2. **SMS analysis** performed (toxicity, flags)
3. **MessageModel** created with analysis data
4. **Firebase** stores message with analysis fields
5. **Parent UI** shows analysis results

## 📱 **Complete Child Fields Summary**

### **Basic Information:**
- ✅ `childId`, `parentId`, `name`, `email`, `userType`, `avatarUrl`
- ✅ `createdAt`, `updatedAt`, `isActive`

### **Device Information:**
- ✅ `deviceInfo` (deviceId, deviceName, osVersion, appVersion, lastSeen)

### **Restrictions:**
- ✅ `restrictions` (app_blocking, time_limits, content_filtering)

### **Location Tracking:**
- ✅ `currentLatitude`, `currentLongitude`, `currentAddress`
- ✅ `locationAccuracy`, `lastLocationUpdate`
- ✅ `isLocationTrackingEnabled`, `currentLocationStatus`
- ✅ `locationHistory` (last 50 locations)

### **Messages (Subcollection):**
- ✅ All message types (text, sms, call_log, location, app_usage)
- ✅ SMS analysis fields (flag, toxScore, toxLabel)
- ✅ Message metadata and attachments

## 🎯 **Key Benefits of This Structure:**

1. **Hierarchical Organization**: Parent → Children → Messages
2. **Real-time Updates**: All data updates in real-time
3. **Location Tracking**: Complete location history and current status
4. **SMS Analysis**: Toxicity detection and flagging
5. **Message Management**: All communication types in one place
6. **Scalable**: Easy to add new features and data types
7. **Secure**: Parent-only access to child data

Yeh complete Firebase structure hai with all child fields including location tracking! 🎉
