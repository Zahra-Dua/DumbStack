# Complete Firebase Structure - Parental Control App

## 🏗️ **Complete Firebase Structure**

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
│       │   └── messages/ (subcollection)
│       │       ├── {messageId}/
│       │       │   ├── messageId: "msg_1"
│       │       │   ├── childId: "child_1"
│       │       │   ├── parentId: "parent_123"
│       │       │   ├── senderId: "child_1" or "parent_123"
│       │       │   ├── senderType: "child" or "parent"
│       │       │   ├── content: "Hello world"
│       │       │   ├── messageType: "text", "image", "call_log", "sms", "location"
│       │       │   ├── metadata: {...}
│       │       │   ├── isRead: false
│       │       │   ├── isBlocked: false
│       │       │   ├── timestamp: timestamp
│       │       │   ├── readAt: timestamp
│       │       │   ├── replyToMessageId: "msg_2"
│       │       │   └── attachments: ["url1", "url2"]
│       │       └── {messageId}/
│       │           └── ... (more messages)
│       └── {childId}/
│           └── ... (more children with their messages)
```

## 📱 **Models Created:**

### 1. **ParentModel** 
- ✅ No `avatarUrl` field
- ✅ `parentId` instead of `uid`
- ✅ `childIds` array to track children
- ✅ QR generation methods

### 2. **ChildModel**
- ✅ Complete child information
- ✅ Device info and restrictions
- ✅ QR generation for profiles and device pairing

### 3. **MessageModel**
- ✅ Multiple message types (text, image, call_log, sms, location)
- ✅ Read/unread status
- ✅ Block/unblock functionality
- ✅ Reply system
- ✅ Attachments support
- ✅ Rich metadata for different message types

## 🔥 **Firebase Service Features:**

### **Parent Management:**
- ✅ Create/Read/Update/Delete parents
- ✅ Get parent by email
- ✅ Real-time parent streams

### **Child Management:**
- ✅ Add/Remove children from parent's subcollection
- ✅ Auto-update parent's `childIds` array
- ✅ Get children with real-time updates
- ✅ Child-specific operations

### **Message Management:**
- ✅ Add messages to child's subcollection
- ✅ Get messages by type (text, image, call_log, etc.)
- ✅ Mark messages as read/unread
- ✅ Block/unblock messages
- ✅ Delete messages
- ✅ Get message statistics
- ✅ Real-time message streams

## 🎯 **Message Types Supported:**

### **1. Text Messages:**
```dart
MessageModel.createTextMessage(
  messageId: 'msg_1',
  childId: 'child_1',
  parentId: 'parent_123',
  senderId: 'child_1',
  senderType: 'child',
  content: 'Hello Mom!',
);
```

### **2. Image Messages:**
```dart
MessageModel.createImageMessage(
  messageId: 'msg_2',
  childId: 'child_1',
  parentId: 'parent_123',
  senderId: 'child_1',
  senderType: 'child',
  imageUrl: 'https://example.com/image.jpg',
  caption: 'Look at this!',
);
```

### **3. Call Log Messages:**
```dart
MessageModel.createCallLogMessage(
  messageId: 'msg_3',
  childId: 'child_1',
  parentId: 'parent_123',
  phoneNumber: '+1234567890',
  callType: 'outgoing',
  duration: 120, // 2 minutes
  callTime: DateTime.now(),
);
```

### **4. SMS Messages:**
```dart
MessageModel.createSMSMessage(
  messageId: 'msg_4',
  childId: 'child_1',
  parentId: 'parent_123',
  phoneNumber: '+1234567890',
  messageBody: 'Text message content',
  smsType: 'sent',
  smsTime: DateTime.now(),
);
```

### **5. Location Messages:**
```dart
MessageModel.createLocationMessage(
  messageId: 'msg_5',
  childId: 'child_1',
  parentId: 'parent_123',
  latitude: 37.7749,
  longitude: -122.4194,
  address: 'San Francisco, CA',
  accuracy: 10.0,
);
```

## 🚀 **Usage Examples:**

### **1. Create Parent and Add Child:**
```dart
// Create parent
final parent = ParentModel(
  parentId: 'parent_123',
  name: 'John Doe',
  email: 'john@example.com',
  userType: 'parent',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await FirebaseParentService().createParent(parent);

// Add child
final child = ChildModel(
  childId: 'child_1',
  parentId: 'parent_123',
  name: 'Alice',
  email: 'alice@example.com',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await FirebaseParentService().addChild('parent_123', child);
// This automatically adds childId to parent's childIds array!
```

### **2. Add Messages:**
```dart
// Add text message
final textMessage = MessageModel.createTextMessage(
  messageId: 'msg_1',
  childId: 'child_1',
  parentId: 'parent_123',
  senderId: 'child_1',
  senderType: 'child',
  content: 'Hello from child!',
);

await FirebaseParentService().addMessage('parent_123', 'child_1', textMessage);

// Add call log
final callMessage = MessageModel.createCallLogMessage(
  messageId: 'msg_2',
  childId: 'child_1',
  parentId: 'parent_123',
  phoneNumber: '+1234567890',
  callType: 'outgoing',
  duration: 120,
  callTime: DateTime.now(),
);

await FirebaseParentService().addMessage('parent_123', 'child_1', callMessage);
```

### **3. Get Messages with Real-time Updates:**
```dart
// Get all messages for a child
final messages = await FirebaseParentService().getMessages('parent_123', 'child_1');

// Stream messages for real-time updates
FirebaseParentService().getMessagesStream('parent_123', 'child_1').listen((messages) {
  // Update UI with new messages
  print('New messages: ${messages.length}');
});

// Get messages by type
final callLogs = await FirebaseParentService().getMessagesByType(
  'parent_123', 
  'child_1', 
  'call_log'
);
```

### **4. Message Management:**
```dart
// Mark message as read
await FirebaseParentService().markMessageAsRead('parent_123', 'child_1', 'msg_1');

// Mark all messages as read
await FirebaseParentService().markAllMessagesAsRead('parent_123', 'child_1');

// Block/unblock message
await FirebaseParentService().toggleMessageBlock('parent_123', 'child_1', 'msg_1');

// Delete message
await FirebaseParentService().deleteMessage('parent_123', 'child_1', 'msg_1');

// Get message statistics
final stats = await FirebaseParentService().getMessageStats('parent_123', 'child_1');
print('Total messages: ${stats['total']}');
print('Unread: ${stats['unread']}');
print('Call logs: ${stats['call_log']}');
```

## 🧪 **Demo Pages:**

### **1. QRDemoNewStructurePage**
- ✅ Test parent creation
- ✅ Test child addition
- ✅ QR code generation for all types
- ✅ Navigation to messages page

### **2. MessagesDemoPage**
- ✅ View all messages for a child
- ✅ Add different types of test messages
- ✅ Mark messages as read/unread
- ✅ Block/unblock messages
- ✅ Delete messages
- ✅ Message statistics display

## 📊 **Benefits of This Structure:**

- ✅ **Hierarchical Organization**: Clear parent → child → messages structure
- ✅ **Scalable**: Can handle multiple children per parent
- ✅ **Real-time Updates**: Live message streams
- ✅ **Rich Message Types**: Support for various communication types
- ✅ **Message Management**: Read status, blocking, deletion
- ✅ **Statistics**: Message analytics and insights
- ✅ **Efficient Queries**: Easy to filter by message type, status, etc.
- ✅ **Auto-sync**: Parent's childIds array automatically maintained

## 🎉 **Complete Flow:**

1. **Parent creates account** → Stored in `parents` collection
2. **Parent generates family invite QR** → Others scan to join
3. **Child is added** → Stored in `parents/{parentId}/children` subcollection
4. **Child ID added to parent** → Parent's `childIds` array updated
5. **Messages are added** → Stored in `parents/{parentId}/children/{childId}/messages` subcollection
6. **Real-time monitoring** → Parent can see all child activities
7. **Message management** → Read, block, delete messages as needed

This structure provides a complete parental control system with hierarchical data organization, real-time updates, and comprehensive message management! 🚀
