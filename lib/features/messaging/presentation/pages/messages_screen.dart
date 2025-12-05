import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/models/message_model.dart';

class MessagesScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const MessagesScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessageRemoteDataSourceImpl _messageDataSource = MessageRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
  List<MessageModel> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messageDataSource.getMessages(
        parentId: widget.parentId,
        childId: widget.childId,
      );
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _messageDataSource.sendMessage(
        senderId: widget.parentId,
        receiverId: widget.childId,
        content: _messageController.text.trim(),
        messageType: 'text',
        parentId: widget.parentId,
        childId: widget.childId,
      );

      _messageController.clear();
      _loadMessages(); // Reload messages
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> _markAsSuspicious(MessageModel message) async {
    try {
      await _messageDataSource.markMessageAsSuspicious(
        message.id,
        !message.isSuspicious,
      );
      _loadMessages(); // Reload messages
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        title: Text('Messages with ${widget.childName}'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: mq.h(0.02)),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: mq.sp(0.05),
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: mq.h(0.01)),
                            Text(
                              'Start a conversation with ${widget.childName}',
                              style: TextStyle(
                                fontSize: mq.sp(0.04),
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(mq.w(0.04)),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isFromParent = message.senderId == widget.parentId;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: mq.h(0.01)),
                            child: Row(
                              mainAxisAlignment: isFromParent
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (!isFromParent) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.darkCyan,
                                    child: Text(
                                      widget.childName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: mq.w(0.02)),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: mq.w(0.04),
                                      vertical: mq.h(0.015),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFromParent
                                          ? AppColors.darkCyan
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
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
                                          message.content,
                                          style: TextStyle(
                                            color: isFromParent
                                                ? Colors.white
                                                : AppColors.textDark,
                                            fontSize: mq.sp(0.04),
                                          ),
                                        ),
                                        SizedBox(height: mq.h(0.005)),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatTime(message.timestamp),
                                              style: TextStyle(
                                                color: isFromParent
                                                    ? Colors.white70
                                                    : Colors.grey[600],
                                                fontSize: mq.sp(0.03),
                                              ),
                                            ),
                                            if (message.isSuspicious) ...[
                                              SizedBox(width: mq.w(0.02)),
                                              Icon(
                                                Icons.warning,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isFromParent) ...[
                                  SizedBox(width: mq.w(0.02)),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(mq.w(0.04)),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: mq.w(0.04),
                        vertical: mq.h(0.015),
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: mq.w(0.02)),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: AppColors.darkCyan,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
