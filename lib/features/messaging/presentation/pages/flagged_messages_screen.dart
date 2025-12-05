import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:contacts_service/contacts_service.dart';
// import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/models/message_model.dart';

class FlaggedMessagesScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const FlaggedMessagesScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<FlaggedMessagesScreen> createState() => _FlaggedMessagesScreenState();
}

class _FlaggedMessagesScreenState extends State<FlaggedMessagesScreen> {
  final MessageRemoteDataSourceImpl _messageDataSource = MessageRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
  final Map<String, List<MessageModel>> _groupedMessages = {};
  final Map<String, String> _contactNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlaggedMessages();
  }

  Future<void> _loadFlaggedMessages() async {
    try {
      final messages = await _messageDataSource.getFlaggedMessages(
        parentId: widget.parentId,
        childId: widget.childId,
      );
      
      // Group messages by sender
      _groupMessagesBySender(messages);
      
      // Load contact names
      await _loadContactNames();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading flagged messages: $e')),
      );
    }
  }

  void _groupMessagesBySender(List<MessageModel> messages) {
    _groupedMessages.clear();
    for (final message in messages) {
      final sender = message.senderId;
      
      // Filter out test senders
      if (sender.toLowerCase().contains('test') || 
          sender.toLowerCase().contains('demo') ||
          sender.toLowerCase().contains('sample')) {
        continue; // Skip test messages
      }
      
      if (_groupedMessages.containsKey(sender)) {
        _groupedMessages[sender]!.add(message);
      } else {
        _groupedMessages[sender] = [message];
      }
    }
  }

  Future<void> _loadContactNames() async {
    try {
      // TODO: Implement contacts loading when contacts_service is available
      // For now, we'll use a simple approach
      print('Loading contact names...');
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  String _cleanPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  String _getDisplayName(String senderId) {
    // For now, just return the sender ID (phone number)
    // TODO: Implement contact name lookup when contacts_service is fixed
    return senderId;
  }

  String _getToxicTypeIcon(String? toxicType) {
    switch (toxicType) {
      case 'spam':
        return '📧';
      case 'harassment':
        return '⚠️';
      case 'suspicious':
        return '🚨';
      case 'aggressive':
        return '😡';
      case 'toxic':
        return '☠️';
      case 'threat':
        return '🔪';
      case 'bully':
        return '👊';
      case 'abuse':
        return '💔';
      default:
        return '❓';
    }
  }

  Color _getToxicTypeColor(String? toxicType) {
    switch (toxicType?.toLowerCase()) {
      case 'spam':
        return Colors.orange;
      case 'harassment':
        return Colors.red;
      case 'suspicious':
        return Colors.purple;
      case 'aggressive':
        return Colors.deepOrange;
      case 'toxic':
        return Colors.red[800]!;
      case 'threat':
        return Colors.red[900]!;
      case 'bully':
        return Colors.red[700]!;
      case 'abuse':
        return Colors.pink[700]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Sensitive content'),
        backgroundColor: Colors.blue[100],
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFlaggedMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.green[400],
                      ),
                      SizedBox(height: mq.h(0.02)),
                      Text(
                        'No flagged messages',
                        style: TextStyle(
                          fontSize: mq.sp(0.05),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: mq.h(0.01)),
                      Text(
                        '${widget.childName}\'s messages are safe',
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
                  itemCount: _groupedMessages.length,
                  itemBuilder: (context, index) {
                    final sender = _groupedMessages.keys.elementAt(index);
                    final messages = _groupedMessages[sender]!;
                    final displayName = _getDisplayName(sender);
                    final latestMessage = messages.first; // Most recent message
                    final toxicType = latestMessage.toxicType ?? 'spam';
                    
                    return _buildSenderCard(
                      mq: mq,
                      sender: sender,
                      displayName: displayName,
                      messages: messages,
                      toxicType: toxicType,
                    );
                  },
                ),
    );
  }

  Widget _buildSenderCard({
    required MQ mq,
    required String sender,
    required String displayName,
    required List<MessageModel> messages,
    required String toxicType,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: mq.h(0.015)),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSenderDetails(sender, displayName, messages),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(mq.w(0.04)),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: _getAvatarColor(sender),
                child: _getAvatarContent(displayName),
              ),
              SizedBox(width: mq.w(0.04)),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name/number
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: mq.h(0.005)),
                    
                    // Content description
                    Text(
                      _getContentDescription(toxicType),
                      style: TextStyle(
                        fontSize: mq.sp(0.04),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right side - Time and badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Time
                  Text(
                    _formatTime(messages.first.timestamp),
                    style: TextStyle(
                      fontSize: mq.sp(0.035),
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: mq.h(0.01)),
                  
                  // Badge with count
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${messages.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: mq.sp(0.035),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String sender) {
    // Generate consistent color based on sender
    final colors = [
      Colors.yellow[300],
      Colors.orange[300],
      Colors.purple[300],
      Colors.pink[300],
      Colors.blue[300],
    ];
    final index = sender.hashCode % colors.length;
    return colors[index]!;
  }

  Widget _getAvatarContent(String displayName) {
    if (displayName.isNotEmpty && displayName[0].toUpperCase() != displayName[0].toLowerCase()) {
      // If it's a name (not a phone number), show first letter
      return Text(
        displayName[0].toUpperCase(),
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    } else {
      // If it's a phone number, show person icon
      return Icon(
        Icons.person,
        color: Colors.black87,
        size: 20,
      );
    }
  }

  String _getContentDescription(String toxicType) {
    switch (toxicType.toLowerCase()) {
      case 'spam':
        return 'Spam content detected';
      case 'harassment':
        return 'Harassment detected - inappropriate language';
      case 'suspicious':
        return 'Suspicious content detected';
      case 'aggressive':
        return 'Aggressive language detected';
      case 'toxic':
        return 'Toxic content detected';
      case 'threat':
        return 'Threatening language detected';
      case 'bully':
        return 'Bullying behavior detected';
      case 'abuse':
        return 'Abusive content detected';
      default:
        return 'Content flagged for review';
    }
  }

  void _showSenderDetails(String sender, String displayName, List<MessageModel> messages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getAvatarColor(sender),
                      child: _getAvatarContent(displayName),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${messages.length} flagged messages',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Messages list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _getToxicTypeColor(message.toxicType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getToxicTypeIcon(message.toxicType),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  message.toxicType?.toUpperCase() ?? 'UNKNOWN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getToxicTypeColor(message.toxicType),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _formatTime(message.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              message.content,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Risk Score: ${(message.riskScore ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 16),
                                if (message.analysisData != null)
                                  Text(
                                    'Analysis: ${message.analysisData!['tox_label'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
}
