import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_child_data_service.dart';
import 'ai_chat_service.dart';

/// Complete Chatbot Service that combines Firebase + AI
/// 
/// This service provides:
/// - Auto-find child by name from parent's message
/// - Fetch full child data
/// - Get AI response with context
/// - Save chat history to Firebase
class ChatbotService {
  final FirebaseChildDataService _firebaseService = FirebaseChildDataService();
  final AIChatService _aiService = AIChatService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initialize AI service with API key (optional - uses config if not provided)
  void initializeAI({String? apiKey}) {
    _aiService.initialize(apiKey: apiKey);
  }

  /// Process chat message - Complete flow
  /// 
  /// Steps:
  /// 1. Extract child name from message
  /// 2. Find childId by name
  /// 3. Get full child data
  /// 4. Get AI response
  /// 5. Save to chat history
  Future<ChatbotResponse> processChat({
    required String userMessage,
    required String parentId,
    String? childName,
  }) async {
    try {
      print('💬 [ChatbotService] Processing chat: "$userMessage"');

      String? childId;
      Map<String, dynamic>? childData;

      // Step 1: Find child (if name provided or extract from message)
      if (childName != null) {
        childId = await _firebaseService.findChildIdByName(childName, parentId: parentId);
      } else {
        // Try to extract name from message (simple: first word after common patterns)
        final extractedName = _extractChildNameFromMessage(userMessage);
        if (extractedName != null) {
          childId = await _firebaseService.findChildIdByName(extractedName, parentId: parentId);
        }
      }

      // Step 2: Get full child data (if child found)
      if (childId != null) {
        childData = await _firebaseService.getFullChildData(childId, parentId: parentId);
        print('✅ [ChatbotService] Found child data for: $childId');
      } else {
        print('⚠️ [ChatbotService] No child found, proceeding without child data');
      }

      // Step 3: Get AI response
      print('🤖 [ChatbotService] Getting AI response...');
      final aiResponse = await _aiService.askAI(
        prompt: userMessage,
        childData: childData,
      );

      // Step 4: Save to chat history
      await _saveChatHistory(
        parentId: parentId,
        userMessage: userMessage,
        aiResponse: aiResponse,
        childId: childId,
      );

      return ChatbotResponse(
        message: aiResponse,
        childId: childId,
        hasChildData: childData != null,
      );
    } catch (e, stackTrace) {
      print('❌ [ChatbotService] Error processing chat: $e');
      print('❌ [ChatbotService] Stack trace: $stackTrace');
      
      String errorMessage = 'Sorry, I encountered an error. Please try again.';
      
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        errorMessage = 'Permission error. Please check Firebase permissions.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('not found') || e.toString().contains('NotFound')) {
        errorMessage = 'Child not found. Please check the child name.';
      }
      
      return ChatbotResponse(
        message: errorMessage,
        error: e.toString(),
      );
    }
  }

  /// Stream chat response (for real-time typing effect)
  Stream<ChatbotResponse> processChatStream({
    required String userMessage,
    required String parentId,
    String? childName,
  }) async* {
    try {
      String? childId;
      Map<String, dynamic>? childData;

      // Find child and get data
      if (childName != null) {
        childId = await _firebaseService.findChildIdByName(childName, parentId: parentId);
      } else {
        final extractedName = _extractChildNameFromMessage(userMessage);
        if (extractedName != null) {
          childId = await _firebaseService.findChildIdByName(extractedName, parentId: parentId);
        }
      }

      if (childId != null) {
        childData = await _firebaseService.getFullChildData(childId, parentId: parentId);
      }

      // Stream AI response
      String fullResponse = '';
      await for (final chunk in _aiService.askAIStream(
        prompt: userMessage,
        childData: childData,
      )) {
        fullResponse += chunk;
        yield ChatbotResponse(
          message: fullResponse,
          childId: childId,
          hasChildData: childData != null,
          isStreaming: true,
        );
      }

      // Save complete response to history
      await _saveChatHistory(
        parentId: parentId,
        userMessage: userMessage,
        aiResponse: fullResponse,
        childId: childId,
      );

      // Final response
      yield ChatbotResponse(
        message: fullResponse,
        childId: childId,
        hasChildData: childData != null,
        isStreaming: false,
      );
    } catch (e, stackTrace) {
      print('❌ [ChatbotService] Error in stream: $e');
      print('❌ [ChatbotService] Stack trace: $stackTrace');
      
      String errorMessage = 'Sorry, I encountered an error. Please try again.';
      
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        errorMessage = 'Permission error. Please check Firebase permissions.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('not found') || e.toString().contains('NotFound')) {
        errorMessage = 'Child not found. Please check the child name.';
      }
      
      yield ChatbotResponse(
        message: errorMessage,
        error: e.toString(),
      );
    }
  }

  /// Extract child name from message (simple pattern matching)
  String? _extractChildNameFromMessage(String message) {
    // Common patterns in Urdu/English
    final patterns = [
      RegExp(r'(\w+)\s+ka\s+', caseSensitive: false), // "Shayan ka"
      RegExp(r'(\w+)\s+ki\s+', caseSensitive: false), // "Shayan ki"
      RegExp(r'(\w+)\s+ke\s+', caseSensitive: false), // "Shayan ke"
      RegExp(r"(\w+)'s\s+", caseSensitive: false),    // "Shayan's"
      RegExp(r'about\s+(\w+)', caseSensitive: false), // "about Shayan"
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null && match.group(1) != null) {
        final name = match.group(1)!;
        // Filter out common words
        if (!['the', 'a', 'an', 'is', 'are', 'was', 'were'].contains(name.toLowerCase())) {
          return name;
        }
      }
    }

    // Fallback: first word (if message starts with name)
    final words = message.trim().split(' ');
    if (words.isNotEmpty && words.first.length > 2) {
      return words.first;
    }

    return null;
  }

  /// Save chat history to Firebase
  Future<void> _saveChatHistory({
    required String parentId,
    required String userMessage,
    required String aiResponse,
    String? childId,
  }) async {
    try {
      await _db
          .collection('parents')
          .doc(parentId)
          .collection('chatHistory')
          .add({
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'childId': childId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      print('✅ [ChatbotService] Chat history saved');
    } catch (e) {
      print('⚠️ [ChatbotService] Error saving chat history: $e');
    }
  }

  /// Get chat history
  Stream<List<Map<String, dynamic>>> getChatHistory(String parentId, {int limit = 50}) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('chatHistory')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }
}

/// Chatbot Response Model
class ChatbotResponse {
  final String message;
  final String? childId;
  final bool hasChildData;
  final bool isStreaming;
  final String? error;

  ChatbotResponse({
    required this.message,
    this.childId,
    this.hasChildData = false,
    this.isStreaming = false,
    this.error,
  });
}

