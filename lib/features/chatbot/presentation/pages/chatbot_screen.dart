import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import '../../data/services/chatbot_service.dart';
import '../../data/config/chatbot_api_config.dart';

/// Chatbot Screen - AI Recommendations and Insights
/// 
/// Complete chat interface for parent to interact with AI assistant
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize chatbot with API key
  Future<void> _initializeChatbot() async {
    if (!ChatbotApiConfig.isApiKeyConfigured) {
      setState(() {
        _messages.add(ChatMessage(
          text: '⚠️ API key not configured. Please add your OpenAI API key in:\nlib/features/chatbot/data/config/chatbot_api_config.dart',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      return;
    }

    _chatbotService.initializeAI();
    setState(() {
      _isInitialized = true;
      _messages.add(ChatMessage(
        text: '👋 Hello! I\'m SafeNest AI Assistant. I can help you understand your children\'s digital activity, screen time, app usage, and more. How can I assist you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  /// Load chat history from Firebase
  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final historyStream = _chatbotService.getChatHistory(user.uid, limit: 20);
      await for (final history in historyStream) {
        if (mounted && history.isNotEmpty) {
          setState(() {
            _messages.clear();
            for (var item in history.reversed) {
              _messages.add(ChatMessage(
                text: item['userMessage'] as String? ?? '',
                isUser: true,
                timestamp: DateTime.now(),
              ));
              _messages.add(ChatMessage(
                text: item['aiResponse'] as String? ?? '',
                isUser: false,
                timestamp: DateTime.now(),
              ));
            }
          });
          _scrollToBottom();
        }
        break; // Only load once
      }
    } catch (e) {
      print('⚠️ Error loading chat history: $e');
    }
  }

  /// Send message to chatbot
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || !_isInitialized) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use chatbot')),
      );
      return;
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Get AI response
    try {
      // Check if AI is initialized
      if (!_isInitialized) {
        setState(() {
          _messages.add(ChatMessage(
            text: '⚠️ AI service is not initialized. Please check API key configuration.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        return;
      }

      await for (final response in _chatbotService.processChatStream(
        userMessage: text,
        parentId: user.uid,
      )) {
        if (!mounted) break;

        setState(() {
          // Remove last message if it was streaming
          if (_messages.isNotEmpty && 
              !_messages.last.isUser && 
              _messages.last.isStreaming) {
            _messages.removeLast();
          }

          // Add/update AI response
          _messages.add(ChatMessage(
            text: response.message,
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: response.isStreaming,
          ));
        });
        _scrollToBottom();
      }
    } catch (e, stackTrace) {
      print('❌ [ChatbotScreen] Error in _sendMessage: $e');
      print('❌ [ChatbotScreen] Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          String errorMsg = 'Sorry, I encountered an error. Please try again.';
          
          if (e.toString().contains('API') || e.toString().contains('apiKey')) {
            errorMsg = 'API key error. Please check your Gemini API key.';
          } else if (e.toString().contains('network') || e.toString().contains('Network')) {
            errorMsg = 'Network error. Please check your internet connection.';
          }
          
          _messages.add(ChatMessage(
            text: errorMsg,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text(
          'AI Recommendations & Insights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 64,
                          color: AppColors.darkCyan.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me anything about your children\'s\n digital activity and safety',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: mq.sp(0.04),
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(mq.w(0.04)),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index], mq);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: mq.w(0.04),
              vertical: mq.h(0.01),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.offWhite,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: mq.w(0.04),
                          vertical: mq.h(0.015),
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCyan,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, MQ mq) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: mq.h(0.015)),
        constraints: BoxConstraints(maxWidth: mq.w(0.75)),
        padding: EdgeInsets.symmetric(
          horizontal: mq.w(0.04),
          vertical: mq.h(0.015),
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.darkCyan : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : AppColors.textDark,
                fontSize: mq.sp(0.04),
              ),
            ),
            if (message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      message.isUser ? Colors.white70 : AppColors.darkCyan,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });
}

