import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parent_model.dart';
import '../models/child_model.dart';
import '../models/message_model.dart';

class FirebaseParentService {
  static const String _parentsCollection = 'parents';
  static const String _childrenSubcollection = 'children';
  static const String _messagesSubcollection = 'messages';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new parent document
  Future<String> createParent(ParentModel parent) async {
    try {
      final docRef = await _firestore
          .collection(_parentsCollection)
          .add(parent.toMap());
      
      // Update the parent with the generated ID
      await _firestore
          .collection(_parentsCollection)
          .doc(docRef.id)
          .update({'parentId': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create parent: $e');
    }
  }

  /// Get parent by ID
  Future<ParentModel?> getParent(String parentId) async {
    try {
      final doc = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return ParentModel.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get parent: $e');
    }
  }

  /// Update parent
  Future<void> updateParent(ParentModel parent) async {
    try {
      await _firestore
          .collection(_parentsCollection)
          .doc(parent.parentId)
          .update(parent.toMap());
    } catch (e) {
      throw Exception('Failed to update parent: $e');
    }
  }

  /// Add child to parent's subcollection and update childIds
  Future<String> addChild(String parentId, ChildModel child) async {
    try {
      // Add child to subcollection
      final childDocRef = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .add(child.toMap());
      
      // Update child with generated ID
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childDocRef.id)
          .update({'childId': childDocRef.id});
      
      // Add child ID to parent's childIds array
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .update({
            'childIds': FieldValue.arrayUnion([childDocRef.id])
          });
      
      return childDocRef.id;
    } catch (e) {
      throw Exception('Failed to add child: $e');
    }
  }

  /// Get all children of a parent
  Future<List<ChildModel>> getChildren(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ChildModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get children: $e');
    }
  }

  /// Get child by ID from parent's subcollection
  Future<ChildModel?> getChild(String parentId, String childId) async {
    try {
      final doc = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .get();
      
      if (doc.exists) {
        return ChildModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get child: $e');
    }
  }

  /// Update child
  Future<void> updateChild(String parentId, ChildModel child) async {
    try {
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(child.childId)
          .update(child.toMap());
    } catch (e) {
      throw Exception('Failed to update child: $e');
    }
  }

  /// Update message
  Future<void> updateMessage(String parentId, String childId, MessageModel message) async {
    try {
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .doc(message.messageId)
          .update(message.toMap());
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  /// Remove child from parent's subcollection and update childIds
  Future<void> removeChild(String parentId, String childId) async {
    try {
      // Remove child from subcollection
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .delete();
      
      // Remove child ID from parent's childIds array
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .update({
            'childIds': FieldValue.arrayRemove([childId])
          });
    } catch (e) {
      throw Exception('Failed to remove child: $e');
    }
  }

  /// Get parent by email
  Future<ParentModel?> getParentByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_parentsCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return ParentModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get parent by email: $e');
    }
  }

  /// Stream of parent's children
  Stream<List<ChildModel>> getChildrenStream(String parentId) {
    return _firestore
        .collection(_parentsCollection)
        .doc(parentId)
        .collection(_childrenSubcollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChildModel.fromMap(doc.data()))
            .toList());
  }

  /// Stream of parent
  Stream<ParentModel?> getParentStream(String parentId) {
    return _firestore
        .collection(_parentsCollection)
        .doc(parentId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return ParentModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // ==================== MESSAGE MANAGEMENT ====================

  /// Add a message to child's messages subcollection
  Future<String> addMessage(String parentId, String childId, MessageModel message) async {
    try {
      final messageDocRef = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .add(message.toMap());
      
      // Update message with generated ID
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .doc(messageDocRef.id)
          .update({'messageId': messageDocRef.id});
      
      return messageDocRef.id;
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  /// Get all messages for a specific child
  Future<List<MessageModel>> getMessages(String parentId, String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Get messages stream for real-time updates
  Stream<List<MessageModel>> getMessagesStream(String parentId, String childId) {
    return _firestore
        .collection(_parentsCollection)
        .doc(parentId)
        .collection(_childrenSubcollection)
        .doc(childId)
        .collection(_messagesSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  /// Get messages by type (text, image, call_log, sms, etc.)
  Future<List<MessageModel>> getMessagesByType(
    String parentId, 
    String childId, 
    String messageType
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .where('messageType', isEqualTo: messageType)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages by type: $e');
    }
  }

  /// Get unread messages count for a child
  Future<int> getUnreadMessagesCount(String parentId, String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .where('isRead', isEqualTo: false)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread messages count: $e');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String parentId, String childId, String messageId) async {
    try {
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .doc(messageId)
          .update({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  /// Mark all messages as read for a child
  Future<void> markAllMessagesAsRead(String parentId, String childId) async {
    try {
      final batch = _firestore.batch();
      final messagesRef = _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .where('isRead', isEqualTo: false);
      
      final querySnapshot = await messagesRef.get();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all messages as read: $e');
    }
  }

  /// Block/unblock a message
  Future<void> toggleMessageBlock(String parentId, String childId, String messageId) async {
    try {
      final messageRef = _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .doc(messageId);
      
      final doc = await messageRef.get();
      if (doc.exists) {
        final currentBlocked = doc.data()?['isBlocked'] ?? false;
        await messageRef.update({'isBlocked': !currentBlocked});
      }
    } catch (e) {
      throw Exception('Failed to toggle message block: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String parentId, String childId, String messageId) async {
    try {
      await _firestore
          .collection(_parentsCollection)
          .doc(parentId)
          .collection(_childrenSubcollection)
          .doc(childId)
          .collection(_messagesSubcollection)
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get recent messages across all children
  Future<List<MessageModel>> getRecentMessages(String parentId, {int limit = 50}) async {
    try {
      final List<MessageModel> allMessages = [];
      
      // Get all children for this parent
      final children = await getChildren(parentId);
      
      // Get recent messages from each child
      for (final child in children) {
        final childMessages = await _firestore
            .collection(_parentsCollection)
            .doc(parentId)
            .collection(_childrenSubcollection)
            .doc(child.childId)
            .collection(_messagesSubcollection)
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();
        
        allMessages.addAll(
          childMessages.docs.map((doc) => MessageModel.fromMap(doc.data()))
        );
      }
      
      // Sort by timestamp and limit
      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allMessages.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recent messages: $e');
    }
  }

  /// Get messages statistics for a child
  Future<Map<String, int>> getMessageStats(String parentId, String childId) async {
    try {
      final messages = await getMessages(parentId, childId);
      
      final stats = <String, int>{
        'total': messages.length,
        'unread': messages.where((m) => !m.isRead).length,
        'blocked': messages.where((m) => m.isBlocked).length,
        'text': messages.where((m) => m.messageType == 'text').length,
        'image': messages.where((m) => m.messageType == 'image').length,
        'call_log': messages.where((m) => m.messageType == 'call_log').length,
        'sms': messages.where((m) => m.messageType == 'sms').length,
        'location': messages.where((m) => m.messageType == 'location').length,
      };
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get message stats: $e');
    }
  }
}
