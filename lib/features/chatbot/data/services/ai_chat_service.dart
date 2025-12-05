import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/chatbot_prompt_config.dart';
import '../config/chatbot_api_config.dart';

/// AI Chat Service using OpenAI API
/// 
/// This service handles:
/// - Initializing OpenAI model
/// - Sending prompts with child data context
/// - Streaming responses for real-time chat
class AIChatService {
  String? _apiKey;
  String? _modelName;
  bool _initialized = false;

  /// Initialize AI service with API key from config
  void initialize({String? apiKey}) {
    if (_initialized && _apiKey != null) {
      print('⚠️ [AIChatService] Already initialized');
      return;
    }

    // Use provided API key or get from config
    final key = apiKey ?? ChatbotApiConfig.openaiApiKey;
    
    if (key.isEmpty || key == 'YOUR_OPENAI_API_KEY_HERE') {
      print('❌ [AIChatService] API key not configured. Please add it in chatbot_api_config.dart');
      _initialized = false;
      return;
    }

    try {
      // Validate API key format
      if (!key.startsWith('sk-')) {
        print('❌ [AIChatService] Invalid API key format. OpenAI keys start with "sk-"');
        _initialized = false;
        return;
      }

      _apiKey = key;
      _modelName = ChatbotApiConfig.modelName;
      _initialized = true;
      print('✅ [AIChatService] Initialized successfully with OpenAI');
      print('✅ [AIChatService] Model: $_modelName');
      print('✅ [AIChatService] API key: ${key.substring(0, 10)}...');
    } catch (e, stackTrace) {
      print('❌ [AIChatService] Error initializing: $e');
      print('❌ [AIChatService] Stack trace: $stackTrace');
      _initialized = false;
    }
  }

  /// Ask AI with child data context
  /// 
  /// [prompt] - User's question/message
  /// [childData] - Complete child data from Firebase (optional)
  Future<String> askAI({
    required String prompt,
    Map<String, dynamic>? childData,
  }) async {
    if (!_initialized || _apiKey == null) {
      return 'AI service is not initialized. Please configure the API key.';
    }

    try {
      print('🤖 [AIChatService] Generating response with OpenAI...');

      // Build context with child data using config
      String context = ChatbotPromptConfig.buildChildDataContext(childData);
      
      final systemMessage = ChatbotPromptConfig.systemPrompt;
      final userMessage = """
Child's Full Firebase Data:

${childData != null ? childData.toString() : 'No child data available.'}

${context.isNotEmpty ? '\n=== FORMATTED DATA SUMMARY ===\n$context\n' : ''}

Parent Question:

$prompt

Your response:
""";

      // OpenAI API call
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': [
            {
              'role': 'system',
              'content': systemMessage,
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text = jsonResponse['choices'][0]['message']['content'] as String;
        print('✅ [AIChatService] Response generated');
        return text;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
        print('❌ [AIChatService] OpenAI API error: $errorMsg');
        return 'Sorry, I encountered an error: $errorMsg. Please try again.';
      }
    } catch (e, stackTrace) {
      print('❌ [AIChatService] Error generating response: $e');
      print('❌ [AIChatService] Stack trace: $stackTrace');
      
      // More specific error messages
      if (e.toString().contains('API_KEY') || e.toString().contains('apiKey') || e.toString().contains('401')) {
        return 'API key error. Please check your OpenAI API key configuration.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        return 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('quota') || e.toString().contains('Quota') || e.toString().contains('429')) {
        return 'API quota exceeded. Please check your OpenAI API quota.';
      } else {
        return 'Sorry, I encountered an error: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}. Please try again.';
      }
    }
  }

  /// Stream AI response for real-time typing effect
  Stream<String> askAIStream({
    required String prompt,
    Map<String, dynamic>? childData,
  }) async* {
    if (!_initialized || _apiKey == null) {
      yield 'AI service is not initialized. Please configure the API key.';
      return;
    }

    try {
      String context = ChatbotPromptConfig.buildChildDataContext(childData);
      
      final systemMessage = ChatbotPromptConfig.systemPrompt;
      final userMessage = """
Child's Full Firebase Data:

${childData != null ? childData.toString() : 'No child data available.'}

${context.isNotEmpty ? '\n=== FORMATTED DATA SUMMARY ===\n$context\n' : ''}

Parent Question:

$prompt

Your response:
""";

      // OpenAI API call with streaming
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': [
            {
              'role': 'system',
              'content': systemMessage,
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
          'stream': true, // Enable streaming
        }),
      );

      if (response.statusCode == 200) {
        // Parse streaming response
        final lines = response.body.split('\n');
        
        for (var line in lines) {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            try {
              final jsonStr = line.substring(6); // Remove 'data: ' prefix
              final jsonData = jsonDecode(jsonStr);
              final delta = jsonData['choices']?[0]?['delta'];
              if (delta != null && delta['content'] != null) {
                final chunk = delta['content'] as String;
                yield chunk;
              }
            } catch (e) {
              // Skip invalid JSON lines
              continue;
            }
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
        print('❌ [AIChatService] OpenAI API error: $errorMsg');
        yield 'Sorry, I encountered an error: $errorMsg. Please try again.';
      }
    } catch (e, stackTrace) {
      print('❌ [AIChatService] Error streaming response: $e');
      print('❌ [AIChatService] Stack trace: $stackTrace');
      
      // More specific error messages
      if (e.toString().contains('API_KEY') || e.toString().contains('apiKey') || e.toString().contains('401')) {
        yield 'API key error. Please check your OpenAI API key configuration.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        yield 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('quota') || e.toString().contains('Quota') || e.toString().contains('429')) {
        yield 'API quota exceeded. Please check your OpenAI API quota.';
      } else {
        final errorMsg = e.toString();
        yield 'Sorry, I encountered an error: ${errorMsg.length > 100 ? errorMsg.substring(0, 100) + "..." : errorMsg}. Please try again.';
      }
    }
  }

}

