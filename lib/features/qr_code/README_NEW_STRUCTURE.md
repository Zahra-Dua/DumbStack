# New Firebase Structure - QR Code Implementation

## 🏗️ **New Firebase Structure**

### **Collections:**
```
parents/
├── {parentId}/
│   ├── parentId: "parent_123"
│   ├── name: "John Doe"
│   ├── email: "john@example.com"
│   ├── userType: "parent"
│   ├── childIds: ["child_1", "child_2", "child_3"]
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│   └── children/ (subcollection)
│       ├── {childId}/
│       │   ├── childId: "child_1"
│       │   ├── parentId: "parent_123"
│       │   ├── name: "Alice"
│       │   ├── email: "alice@example.com"
│       │   ├── userType: "child"
│       │   ├── avatarUrl: ""
│       │   ├── isActive: true
│       │   ├── deviceInfo: {...}
│       │   ├── restrictions: [...]
│       │   ├── createdAt: timestamp
│       │   └── updatedAt: timestamp
│       └── {childId}/
│           └── ... (more children)
```

## 📱 **Key Changes Made:**

### 1. **Parent Model** (`ParentModel`)
- ✅ **Removed** `avatarUrl` field
- ✅ **Renamed** `uid` to `parentId`
- ✅ **Added** `childIds` array to track children
- ✅ **Added** methods to manage children

### 2. **Child Model** (`ChildModel`)
- ✅ **New model** for children
- ✅ **Stored in subcollection** under parent
- ✅ **Includes** device info, restrictions, etc.
- ✅ **QR generation** for child profiles

### 3. **Firebase Service** (`FirebaseParentService`)
- ✅ **Parents collection** instead of users
- ✅ **Children subcollection** under each parent
- ✅ **Automatic childIds management**
- ✅ **CRUD operations** for both parents and children

## 🚀 **How to Use:**

### **1. Create a Parent:**
```dart
final parent = ParentModel(
  parentId: 'parent_123',
  name: 'John Doe',
  email: 'john@example.com',
  userType: 'parent',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await FirebaseParentService().createParent(parent);
```

### **2. Add a Child:**
```dart
final child = ChildModel(
  childId: 'child_1',
  parentId: 'parent_123',
  name: 'Alice',
  email: 'alice@example.com',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await FirebaseParentService().addChild('parent_123', child);
```

### **3. Generate QR Codes:**
```dart
// Parent profile QR
final parentQR = parent.generateQRData();

// Family invite QR
final familyInviteQR = parent.generateFamilyInviteQRData();

// Child profile QR
final childQR = child.generateQRData();

// Device pairing QR
final deviceQR = child.generateDevicePairingQRData('Alice\'s Phone');
```

### **4. Get Parent with Children:**
```dart
// Get parent
final parent = await FirebaseParentService().getParent('parent_123');

// Get all children
final children = await FirebaseParentService().getChildren('parent_123');

// Stream children (real-time updates)
FirebaseParentService().getChildrenStream('parent_123').listen((children) {
  // Update UI with children
});
```

## 🎯 **QR Code Types:**

### **1. Parent Profile QR:**
```json
{
  "type": "user_profile",
  "uid": "parent_123",
  "name": "John Doe",
  "email": "john@example.com",
  "userType": "parent",
  "timestamp": 1234567890
}
```

### **2. Family Invite QR:**
```json
{
  "type": "family_inite",
  "familyId": "parent_123",
  "inviterName": "John Doe",
  "inviterEmail": "john@example.com",
  "timestamp": 1234567890
}
```

### **3. Child Profile QR:**
```json
{
  "type": "user_profile",
  "uid": "child_1",
  "name": "Alice",
  "email": "alice@example.com",
  "userType": "child",
  "timestamp": 1234567890
}
```

### **4. Device Pairing QR:**
```json
{
  "type": "device_pairing",
  "deviceId": "child_1",
  "deviceName": "Alice's Phone",
  "ownerUid": "parent_123",
  "timestamp": 1234567890
}
```

## 🔄 **Data Flow:**

1. **Parent creates account** → Stored in `parents` collection
2. **Parent generates family invite QR** → Others can scan to join
3. **Child is added** → Stored in `parents/{parentId}/children` subcollection
4. **Child ID is added** → To parent's `childIds` array
5. **Child generates QR** → For device pairing or profile sharing

## 📊 **Benefits of New Structure:**

- ✅ **Clear separation** between parents and children
- ✅ **Hierarchical organization** with subcollections
- ✅ **Easy querying** of children by parent
- ✅ **Scalable** for multiple children per parent
- ✅ **Real-time updates** with Firestore streams
- ✅ **Efficient data management** with childIds tracking

## 🧪 **Testing:**

Use the `QRDemoNewStructurePage` to test:
- Parent creation
- Child addition
- QR code generation
- QR code scanning
- Real-time updates

This new structure provides a much cleaner and more organized way to manage parent-child relationships in your parental control app! 🎉
