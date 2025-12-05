import 'package:flutter/material.dart';
import '../../../user_management/data/models/parent_model.dart';
import '../../../user_management/data/models/child_model.dart';
import '../../../user_management/data/models/message_model.dart';
import '../../../user_management/data/datasources/firebase_parent_service.dart';
import '../../../user_management/data/services/sms_analysis_service.dart';

class MessagesDemoPage extends StatefulWidget {
  final ParentModel parent;
  final ChildModel child;

  const MessagesDemoPage({
    super.key,
    required this.parent,
    required this.child,
  });

  @override
  State<MessagesDemoPage> createState() => _MessagesDemoPageState();
}

class _MessagesDemoPageState extends State<MessagesDemoPage> {
  final FirebaseParentService _firebaseService = FirebaseParentService();
  final SmsAnalysisService _smsAnalysisService = SmsAnalysisService();
  List<MessageModel> messages = [];
  bool isLoading = true;
  Map<String, dynamic>? analysisStats;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messagesList = await _firebaseService.getMessages(
        widget.parent.parentId,
        widget.child.childId,
      );
      
      final stats = await _smsAnalysisService.getAnalysisStats(
        parentId: widget.parent.parentId,
        childId: widget.child.childId,
      );
      
      setState(() {
        messages = messagesList;
        analysisStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages - ${widget.child.name}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddMessageDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message Stats
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', messages.length.toString(), Colors.blue),
                    _buildStatCard('Unread', 
                      messages.where((m) => !m.isRead).length.toString(), 
                      Colors.red),
                    _buildStatCard('Blocked', 
                      messages.where((m) => m.isBlocked).length.toString(), 
                      Colors.orange),
                  ],
                ),
                if (analysisStats != null) ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('SMS', 
                        analysisStats!['total'].toString(), 
                        Colors.green),
                      _buildStatCard('Toxic', 
                        analysisStats!['toxic'].toString(), 
                        Colors.red),
                      _buildStatCard('Flagged', 
                        analysisStats!['flagged'].toString(), 
                        Colors.orange),
                      _buildStatCard('Avg Score', 
                        analysisStats!['averageToxScore'].toStringAsFixed(2), 
                        Colors.purple),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add some test messages to see them here',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageCard(message);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMessageDialog,
        backgroundColor: Colors.blue[700],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: message.isFromParent ? Colors.blue : Colors.green,
          child: Icon(
            message.isFromParent ? Icons.person : Icons.child_care,
            color: Colors.white,
          ),
        ),
        title: Text(
          message.displayText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${message.messageType} | ${message.formattedTime}',
              style: TextStyle(fontSize: 12),
            ),
            // SMS Analysis Info
            if (message.messageType == 'sms' && message.toxScore != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getToxicityColor(message.toxScore!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${message.toxicityLevel} (${(message.toxScore! * 100).toInt()}%)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (message.isFlagged) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        message.flagDescription,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (message.isBlocked)
              Text(
                'BLOCKED',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            if (!message.isRead)
              Text(
                'UNREAD',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isRead)
              IconButton(
                icon: Icon(Icons.mark_email_read),
                onPressed: () => _markAsRead(message),
              ),
            IconButton(
              icon: Icon(
                message.isBlocked ? Icons.block : Icons.block_outlined,
                color: message.isBlocked ? Colors.red : Colors.grey,
              ),
              onPressed: () => _toggleBlock(message),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteMessage(message),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMessageDialog(
        parentId: widget.parent.parentId,
        childId: widget.child.childId,
        onMessageAdded: () {
          _loadMessages();
        },
      ),
    );
  }

  Future<void> _markAsRead(MessageModel message) async {
    try {
      await _firebaseService.markMessageAsRead(
        widget.parent.parentId,
        widget.child.childId,
        message.messageId,
      );
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking as read: $e')),
      );
    }
  }

  Future<void> _toggleBlock(MessageModel message) async {
    try {
      await _firebaseService.toggleMessageBlock(
        widget.parent.parentId,
        widget.child.childId,
        message.messageId,
      );
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling block: $e')),
      );
    }
  }

  Future<void> _deleteMessage(MessageModel message) async {
    try {
      await _firebaseService.deleteMessage(
        widget.parent.parentId,
        widget.child.childId,
        message.messageId,
      );
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  Color _getToxicityColor(double score) {
    if (score < 0.3) return Colors.green;
    if (score < 0.6) return Colors.orange;
    if (score < 0.8) return Colors.red;
    return Colors.purple;
  }
}

class AddMessageDialog extends StatefulWidget {
  final String parentId;
  final String childId;
  final VoidCallback onMessageAdded;

  const AddMessageDialog({
    super.key,
    required this.parentId,
    required this.childId,
    required this.onMessageAdded,
  });

  @override
  State<AddMessageDialog> createState() => _AddMessageDialogState();
}

class _AddMessageDialogState extends State<AddMessageDialog> {
  final FirebaseParentService _firebaseService = FirebaseParentService();
  String _messageType = 'text';
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _flagController = TextEditingController(text: '0');
  final TextEditingController _toxScoreController = TextEditingController(text: '0.0');
  final TextEditingController _toxLabelController = TextEditingController(text: 'safe');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Test Message',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Message Type Dropdown
            DropdownButtonFormField<String>(
              value: _messageType,
              decoration: InputDecoration(labelText: 'Message Type'),
              items: [
                DropdownMenuItem(value: 'text', child: Text('Text Message')),
                DropdownMenuItem(value: 'image', child: Text('Image')),
                DropdownMenuItem(value: 'call_log', child: Text('Call Log')),
                DropdownMenuItem(value: 'sms', child: Text('SMS')),
                DropdownMenuItem(value: 'location', child: Text('Location')),
              ],
              onChanged: (value) {
                setState(() {
                  _messageType = value!;
                });
              },
            ),
            SizedBox(height: 16),
            
            // Content Field
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: _messageType == 'call_log' || _messageType == 'sms' 
                    ? 'Description' : 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            // Phone Number Field (for call_log and sms)
            if (_messageType == 'call_log' || _messageType == 'sms') ...[
              SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
            
            // SMS Analysis Fields (for sms only)
            if (_messageType == 'sms') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _flagController,
                      decoration: InputDecoration(
                        labelText: 'Flag (0-3)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _toxScoreController,
                      decoration: InputDecoration(
                        labelText: 'Tox Score (0.0-1.0)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _toxLabelController,
                decoration: InputDecoration(
                  labelText: 'Tox Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _addMessage,
                  child: Text('Add Message'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMessage() async {
    try {
      MessageModel message;
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
      
      switch (_messageType) {
        case 'text':
          message = MessageModel.createTextMessage(
            messageId: messageId,
            childId: widget.childId,
            parentId: widget.parentId,
            senderId: widget.childId, // Child sent the message
            senderType: 'child',
            content: _contentController.text,
          );
          break;
          
        case 'image':
          message = MessageModel.createImageMessage(
            messageId: messageId,
            childId: widget.childId,
            parentId: widget.parentId,
            senderId: widget.childId,
            senderType: 'child',
            imageUrl: 'https://via.placeholder.com/300',
            caption: _contentController.text,
          );
          break;
          
        case 'call_log':
          message = MessageModel.createCallLogMessage(
            messageId: messageId,
            childId: widget.childId,
            parentId: widget.parentId,
            phoneNumber: _phoneController.text,
            callType: 'outgoing',
            duration: 120, // 2 minutes
            callTime: DateTime.now(),
          );
          break;
          
        case 'sms':
          message = MessageModel.createSMSMessage(
            messageId: messageId,
            childId: widget.childId,
            parentId: widget.parentId,
            phoneNumber: _phoneController.text,
            messageBody: _contentController.text,
            smsType: 'sent',
            smsTime: DateTime.now(),
            flag: int.tryParse(_flagController.text) ?? 0,
            toxScore: double.tryParse(_toxScoreController.text) ?? 0.0,
            toxLabel: _toxLabelController.text,
          );
          break;
          
        case 'location':
          message = MessageModel.createLocationMessage(
            messageId: messageId,
            childId: widget.childId,
            parentId: widget.parentId,
            latitude: 37.7749,
            longitude: -122.4194,
            address: _contentController.text,
            accuracy: 10.0,
          );
          break;
          
        default:
          throw Exception('Invalid message type');
      }
      
      await _firebaseService.addMessage(widget.parentId, widget.childId, message);
      
      Navigator.pop(context);
      widget.onMessageAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding message: $e')),
      );
    }
  }
}
