import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation_model.dart';
import '../../../chatbot/data/services/ai_chat_service.dart';
import '../../../chatbot/data/services/firebase_child_data_service.dart';
import '../../../chatbot/data/config/chatbot_prompt_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../chatbot/data/config/chatbot_api_config.dart';

/// AI Recommendation Service
/// 
/// Generates personalized content recommendations for children
/// based on their activity data using AI
class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIChatService _aiService = AIChatService();
  final FirebaseChildDataService _childDataService = FirebaseChildDataService();

  /// Initialize AI service
  void initialize() {
    _aiService.initialize();
  }

  /// Generate recommendations for all children of a parent
  Future<void> generateRecommendationsForAllChildren(String parentId) async {
    try {
      print('🤖 [RecommendationService] Generating recommendations for all children...');
      
      // Get all children
      final childrenSnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .get();

      if (childrenSnapshot.docs.isEmpty) {
        print('⚠️ [RecommendationService] No children found');
        return;
      }

      print('📱 [RecommendationService] Found ${childrenSnapshot.docs.length} children');

      int totalRecommendations = 0;
      final Map<String, int> recommendationsByChild = {};

      // Generate recommendation for each child
      for (final childDoc in childrenSnapshot.docs) {
        final childId = childDoc.id;
        final childData = childDoc.data();
        final childName = childData['name'] ?? childData['firstName'] ?? 'Child';
        
        print('🤖 [RecommendationService] Generating recommendation for: $childName ($childId)');
        
        final generated = await _generateRecommendationForChild(
          parentId: parentId,
          childId: childId,
          childName: childName,
        );
        
        if (generated) {
          totalRecommendations++;
          recommendationsByChild[childName] = (recommendationsByChild[childName] ?? 0) + 1;
        }
      }

      // Save last generation timestamp
      await _saveLastGenerationTimestamp(parentId);

      // Send summary notification
      if (totalRecommendations > 0) {
        await _sendSummaryNotification(parentId, totalRecommendations, recommendationsByChild);
      }

      print('✅ [RecommendationService] Recommendations generated for all children');
    } catch (e) {
      print('❌ [RecommendationService] Error generating recommendations: $e');
    }
  }

  /// Save last generation timestamp to Firebase
  Future<void> _saveLastGenerationTimestamp(String parentId) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .update({
        'lastRecommendationTimestamp': FieldValue.serverTimestamp(),
      });
      print('✅ [RecommendationService] Last generation timestamp saved');
    } catch (e) {
      print('❌ [RecommendationService] Error saving timestamp: $e');
    }
  }

  /// Get last generation timestamp
  Future<DateTime?> getLastGenerationTimestamp(String parentId) async {
    try {
      final doc = await _firestore
          .collection('parents')
          .doc(parentId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        final timestamp = data?['lastRecommendationTimestamp'];
        if (timestamp != null) {
          if (timestamp is Timestamp) {
            return timestamp.toDate();
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ [RecommendationService] Error getting timestamp: $e');
      return null;
    }
  }

  /// Generate recommendation for a specific child
  /// Returns true if recommendation was generated successfully
  Future<bool> _generateRecommendationForChild({
    required String parentId,
    required String childId,
    required String childName,
  }) async {
    try {
      // Get full child activity data
      final childData = await _childDataService.getFullChildData(childId, parentId: parentId);
      
      if (childData == null || childData.isEmpty) {
        print('⚠️ [RecommendationService] No data available for child: $childName');
        return false;
      }

      // Extract child name from profile data if available (more reliable)
      String finalChildName = childName;
      if (childData['profile'] != null) {
        final profile = childData['profile'] as Map<String, dynamic>?;
        if (profile != null) {
          finalChildName = profile['name'] ?? 
                          profile['firstName'] ?? 
                          '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
          if (finalChildName.isEmpty) {
            finalChildName = childName; // Fallback to original
          }
        }
      }

      print('👤 [RecommendationService] Using child name: $finalChildName');

      // Generate AI recommendation
      final recommendation = await _generateAIRecommendation(childData, finalChildName);
      
      if (recommendation.isEmpty) {
        print('⚠️ [RecommendationService] Empty recommendation generated');
        return false;
      }

      // Save to Firebase
      await _saveRecommendation(
        parentId: parentId,
        childId: childId,
        childName: finalChildName,
        recommendation: recommendation,
        childActivityData: childData,
      );

      // Send notification to parent
      await _sendRecommendationNotification(
        parentId: parentId,
        childName: finalChildName,
        recommendation: recommendation,
      );

      print('✅ [RecommendationService] Recommendation generated and saved for: $finalChildName');
      return true;
    } catch (e) {
      print('❌ [RecommendationService] Error generating recommendation for child: $e');
      return false;
    }
  }

  /// Generate AI recommendation based on child activity data
  Future<String> _generateAIRecommendation(
    Map<String, dynamic> childData,
    String childName,
  ) async {
    try {
      if (!ChatbotApiConfig.isApiKeyConfigured) {
        print('⚠️ [RecommendationService] OpenAI API key not configured');
        return '';
      }

      // Build recommendation prompt
      final context = ChatbotPromptConfig.buildChildDataContext(childData);
      
      final systemPrompt = """You are an expert child development and digital wellness advisor. 
Your role is to analyze a child's digital activity data and provide personalized, actionable recommendations to parents.

Focus on:
- Screen time management
- App usage patterns
- Healthy digital habits
- Age-appropriate content
- Sleep and bedtime routines
- Physical activity encouragement

Provide clear, concise, and actionable recommendations in 2-3 sentences.""";

      final userPrompt = """
Child's Name: $childName

Child's Activity Data:
${childData.toString()}

${context.isNotEmpty ? '\n=== ACTIVITY SUMMARY ===\n$context\n' : ''}

Based on this data, provide a personalized recommendation for the parent about how to better manage their child's digital wellness and activities. 
Focus on specific, actionable advice based on the patterns you see in the data.

Recommendation:""";

      // Call OpenAI API
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ChatbotApiConfig.openaiApiKey}',
        },
        body: jsonEncode({
          'model': ChatbotApiConfig.modelName,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userPrompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final recommendation = responseData['choices'][0]['message']['content'] as String;
        return recommendation.trim();
      } else {
        print('❌ [RecommendationService] OpenAI API error: ${response.statusCode}');
        print('Response: ${response.body}');
        return '';
      }
    } catch (e) {
      print('❌ [RecommendationService] Error calling AI: $e');
      return '';
    }
  }

  /// Save recommendation to Firebase
  Future<void> _saveRecommendation({
    required String parentId,
    required String childId,
    required String childName,
    required String recommendation,
    required Map<String, dynamic> childActivityData,
  }) async {
    try {
      final recommendationRef = _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('recommendations')
          .doc();

      final recommendationModel = RecommendationModel(
        id: recommendationRef.id,
        parentId: parentId,
        childId: childId,
        childName: childName,
        recommendation: recommendation,
        timestamp: DateTime.now(),
        status: RecommendationStatus.pending,
        childActivityData: childActivityData,
      );

      await recommendationRef.set(recommendationModel.toMap());
      
      print('✅ [RecommendationService] Recommendation saved to Firebase');
    } catch (e) {
      print('❌ [RecommendationService] Error saving recommendation: $e');
      rethrow;
    }
  }

  /// Send notification to parent about new recommendation
  Future<void> _sendRecommendationNotification({
    required String parentId,
    required String childName,
    required String recommendation,
  }) async {
    try {
      // Create notification in Firebase
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .add({
        'type': 'ai_recommendation',
        'title': 'New AI Recommendation for $childName',
        'body': recommendation.length > 100 
            ? '${recommendation.substring(0, 100)}...' 
            : recommendation,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          'childName': childName,
          'recommendation': recommendation,
        },
      });

      print('✅ [RecommendationService] Notification sent to parent');
    } catch (e) {
      print('❌ [RecommendationService] Error sending notification: $e');
    }
  }

  /// Send summary notification after generating recommendations for all children
  Future<void> _sendSummaryNotification(
    String parentId,
    int totalRecommendations,
    Map<String, int> recommendationsByChild,
  ) async {
    try {
      String title;
      String body;

      if (recommendationsByChild.length == 1) {
        // Single child
        final childName = recommendationsByChild.keys.first;
        final count = recommendationsByChild[childName]!;
        if (count == 1) {
          title = 'New AI Recommendation';
          body = '1 new recommendation available for $childName.';
        } else {
          title = 'New AI Recommendations';
          body = '$count new recommendations available for $childName.';
        }
      } else {
        // Multiple children
        title = 'New AI Recommendations';
        if (totalRecommendations == 1) {
          body = '1 new recommendation available for your children.';
        } else {
          body = '$totalRecommendations new recommendations available for your children.';
        }
      }

      // Create notification in Firebase
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .add({
        'type': 'ai_recommendation_summary',
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': {
          'totalRecommendations': totalRecommendations,
          'recommendationsByChild': recommendationsByChild,
          'action': 'open_recommendations_tab',
        },
      });

      print('✅ [RecommendationService] Summary notification sent: $body');
    } catch (e) {
      print('❌ [RecommendationService] Error sending summary notification: $e');
    }
  }

  /// Get recommendations stream for a parent (all children)
  Stream<List<RecommendationModel>> getRecommendationsStream(String parentId) {
    // This is complex - need to combine streams from all children
    // For now, return empty stream - will implement properly
    return Stream.value([]);
  }

  /// Get recommendations for a specific child
  Stream<List<RecommendationModel>> getChildRecommendationsStream({
    required String parentId,
    required String childId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('recommendations')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecommendationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Approve a recommendation
  Future<void> approveRecommendation({
    required String parentId,
    required String childId,
    required String recommendationId,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('recommendations')
          .doc(recommendationId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [RecommendationService] Recommendation approved');
    } catch (e) {
      print('❌ [RecommendationService] Error approving recommendation: $e');
      rethrow;
    }
  }

  /// Reject a recommendation
  Future<void> rejectRecommendation({
    required String parentId,
    required String childId,
    required String recommendationId,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('recommendations')
          .doc(recommendationId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [RecommendationService] Recommendation rejected');
    } catch (e) {
      print('❌ [RecommendationService] Error rejecting recommendation: $e');
      rethrow;
    }
  }

  /// Delete a recommendation
  Future<void> deleteRecommendation({
    required String parentId,
    required String childId,
    required String recommendationId,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('recommendations')
          .doc(recommendationId)
          .delete();

      print('✅ [RecommendationService] Recommendation deleted');
    } catch (e) {
      print('❌ [RecommendationService] Error deleting recommendation: $e');
      rethrow;
    }
  }
}

