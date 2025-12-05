import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/services/child_message_monitor_service.dart';
import '../../data/datasources/message_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageTestScreen extends StatefulWidget {
  const MessageTestScreen({super.key});

  @override
  State<MessageTestScreen> createState() => _MessageTestScreenState();
}

class _MessageTestScreenState extends State<MessageTestScreen> {
  late ChildMessageMonitorService _messageMonitor;
  String _statusMessage = 'Ready to test';
  bool _isLoading = false;
  String? _parentId;
  String? _childId;

  @override
  void initState() {
    super.initState();
    _loadIds();
    _messageMonitor = ChildMessageMonitorService(
      dataSource: MessageRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      ),
    );
  }

  Future<void> _loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _parentId = prefs.getString('parent_uid');
      _childId = prefs.getString('child_uid');
    });
  }

  Future<void> _testMessageMonitoring() async {
    if (_parentId == null || _childId == null) {
      setState(() {
        _statusMessage = 'Error: Parent or child ID not found';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing message monitoring...';
    });

    try {
      print('🧪 TESTING: Starting manual message monitoring test');
      
      // Test message monitoring
      await _messageMonitor.initialize();

      setState(() {
        _statusMessage = 'Message monitoring test completed! Check console for logs.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testDirectMonitoring() async {
    if (_parentId == null || _childId == null) {
      setState(() {
        _statusMessage = 'Error: Parent or child ID not found';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing direct monitoring...';
    });

    try {
      print('🧪 DIRECT TEST: Starting direct message monitoring');
      
      final messageDataSource = MessageRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      );
      
      await messageDataSource.monitorChildMessages(
        parentId: _parentId!,
        childId: _childId!,
      );

      setState(() {
        _statusMessage = 'Direct monitoring test completed! Check console for logs.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTimestamp() async {
    if (_childId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_message_timestamp_$_childId');
    
    setState(() {
      _statusMessage = 'Timestamp cleared. Next run will process all messages.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        title: const Text('Message Test'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Padding(
        padding: EdgeInsets.all(mq.w(0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(mq.w(0.04)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Status',
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: mq.h(0.02)),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: mq.sp(0.04),
                        color: _statusMessage.contains('Error') ? Colors.red : AppColors.textDark,
                      ),
                    ),
                    if (_isLoading) ...[
                      SizedBox(height: mq.h(0.02)),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: mq.h(0.04)),
            
            // IDs Display
            Card(
              child: Padding(
                padding: EdgeInsets.all(mq.w(0.04)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current IDs',
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: mq.h(0.02)),
                    Text(
                      'Parent ID: ${_parentId ?? "Not found"}',
                      style: TextStyle(
                        fontSize: mq.sp(0.04),
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Child ID: ${_childId ?? "Not found"}',
                      style: TextStyle(
                        fontSize: mq.sp(0.04),
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: mq.h(0.04)),
            
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testMessageMonitoring,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Monitoring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: mq.w(0.04)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testDirectMonitoring,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Direct Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: mq.h(0.02)),
            
            // Clear Timestamp Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearTimestamp,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Timestamp (Process All Messages)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            SizedBox(height: mq.h(0.04)),
            
            // Instructions
            Card(
              child: Padding(
                padding: EdgeInsets.all(mq.w(0.04)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: mq.h(0.02)),
                    Text(
                      '1. Make sure Python Flask server is running\n'
                      '2. Click "Test Monitoring" to start monitoring\n'
                      '3. Click "Direct Test" for immediate test\n'
                      '4. Click "Clear Timestamp" to process all messages\n'
                      '5. Check console logs for detailed output\n'
                      '6. Check Firebase for flagged messages',
                      style: TextStyle(
                        fontSize: mq.sp(0.04),
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageMonitor.stop();
    super.dispose();
  }
}