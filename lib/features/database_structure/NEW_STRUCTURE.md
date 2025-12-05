# New Database Structure - Parental Control App

## 🏗️ **Updated Firebase Structure**

### **1. Parents Collection**
```
parents/
├── {parentId}/
│   ├── uid: "parent_123" (same as parentId)
│   ├── name: "John Doe"
│   ├── email: "john@example.com"
│   ├── userType: "parent"
│   ├── childrenIds: ["child_1", "child_2", "child_3"]
│   ├── createdAt: Timestamp
│   ├── updatedAt: Timestamp
│   └── children/ (subcollection)
```

### **2. Children Subcollection (Under Each Parent)**
```
parents/{parentId}/children/
├── {childId}/
│   ├── uid: "child_1"
│   ├── name: "Alice Doe"
│   ├── email: "alice@example.com"
│   ├── userType: "child"
│   ├── age: 12
│   ├── gender: "Female"
│   ├── hobbies: ["Reading", "Swimming", "Photography"]
│   ├── createdAt: Timestamp
│   ├── updatedAt: Timestamp
│   ├── messages/ (subcollection)
│   │   ├── {messageId}/
│   │   │   ├── id: "msg_123"
│   │   │   ├── message: "Hello from parent"
│   │   │   ├── type: "parent" | "child" | "system" | "emergency"
│   │   │   ├── timestamp: Timestamp
│   │   │   ├── senderId: "parent_123"
│   │   │   ├── receiverId: "child_1"
│   │   │   ├── isRead: false
│   │   │   └── metadata: {...}
│   │   └── ...
│   └── location/ (subcollection)
│       ├── current/
│       │   ├── latitude: 37.7749
│       │   ├── longitude: -122.4194
│       │   ├── address: "123 Main St, San Francisco, CA"
│       │   ├── accuracy: 10.5
│       │   ├── timestamp: Timestamp
│       │   ├── isTrackingEnabled: true
│       │   └── status: "online" | "offline" | "unknown"
│       └── history/
│           └── locations/
│               ├── {locationId}/
│               │   ├── latitude: 37.7749
│               │   ├── longitude: -122.4194
│               │   ├── address: "123 Main St, San Francisco, CA"
│               │   ├── accuracy: 10.5
│               │   ├── timestamp: Timestamp
│               │   ├── isTrackingEnabled: true
│               │   └── status: "online"
│               └── ...
```

## 📱 **Key Changes Made:**

### **1. Collection Renamed**
- ✅ **`users` → `parents`** collection
- ✅ **Only parents** stored in main collection
- ✅ **Children** stored in parent's subcollection only

### **2. Removed Fields**
- ✅ **Removed `avatarUrl`** from all models
- ✅ **Removed `parentId`** field - using `uid` as parent ID
- ✅ **Removed child data** from main collection

### **3. New Subcollections**
- ✅ **`messages`** subcollection under each child
- ✅ **`location`** subcollection under each child
- ✅ **Location tracking** with current and history

### **4. Updated Models**
- ✅ **UserEntity** - removed avatarUrl
- ✅ **ParentModel** - removed avatarUrl, using uid as parentId
- ✅ **ChildUser** - removed parentId field
- ✅ **LocationModel** - new model for location tracking
- ✅ **MessageModel** - new model for messaging

## 🚀 **Benefits of New Structure:**

1. **Better Organization**: Children data is properly nested under parents
2. **No Duplication**: Child data exists only in subcollections
3. **Scalable**: Easy to add more subcollections (notifications, settings, etc.)
4. **Location Tracking**: Built-in location history and current position
5. **Messaging**: Parent-child communication system
6. **Cleaner Code**: Removed unnecessary fields and simplified models

## 🔧 **Implementation Details:**

### **Location Tracking:**
- Current location stored in `location/current/`
- Location history in `location/history/locations/`
- Real-time updates with timestamps
- Tracking enable/disable functionality

### **Messaging System:**
- Messages stored in `messages/` subcollection
- Support for different message types
- Read/unread status tracking
- Metadata support for rich messages

### **Data Flow:**
1. **Parent creates account** → stored in `parents/` collection
2. **Child scans QR** → created in parent's `children/` subcollection
3. **Location updates** → stored in child's `location/` subcollection
4. **Messages** → stored in child's `messages/` subcollection

This new structure provides a clean, scalable foundation for the parental control app! 🎉
