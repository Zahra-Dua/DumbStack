import 'dart:async';
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/call_log_model.dart';
import '../../data/datasources/call_log_remote_datasource.dart';
import '../../data/services/flagged_calls_detector_service.dart';
import '../widgets/call_history_card.dart';

class CallHistoryScreen extends StatefulWidget {
  final String parentId;
  final String childId;
  final String childName;

  const CallHistoryScreen({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
  });

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallLogRemoteDataSourceImpl _dataSource =
      CallLogRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
  List<CallLogModel> _callLogs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  StreamSubscription<List<CallLogModel>>? _streamSubscription;
  final Set<String> _checkedCallIds = {}; // Track which calls have been checked

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
    _startListening(); // Start real-time stream
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// Start listening to real-time call logs stream
  void _startListening() {
    print('🔔 [CallHistory] Starting real-time stream for call logs...');
    _streamSubscription = _dataSource.getCallLogsStream(
      parentId: widget.parentId,
      childId: widget.childId,
    ).listen(
      (callLogs) {
        print('📥 [CallHistory] Stream update: ${callLogs.length} calls');
        
        // Filter last 24 hours
        final last24h = DateTime.now().subtract(const Duration(hours: 24));
        final recentLogs = callLogs.where((c) => c.dateTime.isAfter(last24h)).toList();
        
        if (mounted) {
          setState(() {
            _callLogs = _dedupeAndSort(recentLogs);
            _isLoading = false;
          });
        }
        
        // Check NEW calls only (not already checked)
        final newCalls = recentLogs.where((call) => !_checkedCallIds.contains(call.id)).toList();
        if (newCalls.isNotEmpty) {
          print('🆕 [CallHistory] ${newCalls.length} new calls detected - checking for suspicious activity...');
          _checkFlaggedCalls(newCalls);
          // Mark as checked
          for (final call in newCalls) {
            _checkedCallIds.add(call.id);
          }
        }
      },
      onError: (error) {
        print('❌ [CallHistory] Stream error: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  /// Manual refresh (reloads from Firebase)
  Future<void> _loadCallLogs() async {
    setState(() => _isLoading = true);

    try {
      print('📞 [CallHistory] Loading call logs...');
      final callLogs = await _dataSource.getCallLogs(
        parentId: widget.parentId,
        childId: widget.childId,
      );

      // Filter last 24 hours
      final last24h = DateTime.now().subtract(const Duration(hours: 24));
      final recentLogs = callLogs.where((c) => c.dateTime.isAfter(last24h)).toList();

      setState(() {
        _callLogs = _dedupeAndSort(recentLogs);
        _isLoading = false;
      });

      print('✅ [CallHistory] Loaded ${_callLogs.length} call logs (last 24h)');
      
      // Check and flag suspicious calls
      _checkFlaggedCalls(recentLogs);
    } catch (e) {
      print('❌ [CallHistory] Error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading call logs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<CallLogModel> get _filteredCallLogs {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final logs24h = _callLogs.where((c) => c.dateTime.isAfter(last24h));

    if (_selectedFilter == 'All') return logs24h.toList();

    CallType? filterType;
    switch (_selectedFilter) {
      case 'Incoming':
        filterType = CallType.incoming;
        break;
      case 'Outgoing':
        filterType = CallType.outgoing;
        break;
      case 'Missed':
        filterType = CallType.missed;
        break;
    }

    return logs24h.where((c) => c.type == filterType).toList();
  }

  /// Remove duplicates & sort newest first
  List<CallLogModel> _dedupeAndSort(List<CallLogModel> logs) {
    final seen = <String>{};
    final deduped = <CallLogModel>[];

    for (final log in logs) {
      final key = '${log.id}_${log.number}_${log.type}_${log.dateTime.millisecondsSinceEpoch}_${log.duration}';
      if (seen.add(key)) deduped.add(log);
    }

    deduped.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return deduped;
  }

  /// Check calls for suspicious activity and flag them
  Future<void> _checkFlaggedCalls(List<CallLogModel> callLogs) async {
    try {
      print('🔍 [CallHistory] Checking ${callLogs.length} calls for suspicious activity...');
      final detector = FlaggedCallsDetectorService(
        firestore: FirebaseFirestore.instance,
        parentId: widget.parentId,
        childId: widget.childId,
      );
      await detector.checkAndFlagCalls(callLogs);
    } catch (e) {
      print('⚠️ [CallHistory] Error checking flagged calls: $e');
    }
  }

  String _formatFullDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
  String _formatFullTime(DateTime dt) => '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  void _showCallDetails(CallLogModel callLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(callLog.name ?? callLog.number),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (callLog.name != null) Text('Number: ${callLog.number}'),
            const SizedBox(height: 8),
            Text('Type: ${callLog.callTypeString}'),
            const SizedBox(height: 8),
            Text('Duration: ${callLog.durationString}'),
            const SizedBox(height: 8),
            Text('Date: ${_formatFullDate(callLog.dateTime)}'),
            const SizedBox(height: 8),
            Text('Time: ${_formatFullTime(callLog.dateTime)}'),
            if (callLog.simDisplayName != null)
              Text('SIM: ${callLog.simDisplayName}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: Text('${widget.childName}\'s Call History', style: const TextStyle(color: AppColors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCallLogs)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips
            Container(
              padding: EdgeInsets.symmetric(horizontal: mq.w(0.04), vertical: mq.h(0.01)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All','Incoming','Outgoing','Missed'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: EdgeInsets.only(right: mq.w(0.02)),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) { setState(() => _selectedFilter = filter); },
                        selectedColor: AppColors.darkCyan.withOpacity(0.2),
                        checkmarkColor: AppColors.darkCyan,
                        labelStyle: TextStyle(color: isSelected ? AppColors.darkCyan : AppColors.textDark, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Call Logs List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.darkCyan)))
                  : _filteredCallLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_end, size: 64, color: Colors.grey[400]),
                              SizedBox(height: mq.h(0.02)),
                              Text('No call logs found', style: TextStyle(fontSize: mq.sp(0.05), color: Colors.grey[600], fontWeight: FontWeight.w500)),
                              SizedBox(height: mq.h(0.01)),
                              Text('Call logs will appear here once calls are made', style: TextStyle(fontSize: mq.sp(0.04), color: Colors.grey[500]), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: mq.h(0.01)),
                          itemCount: _filteredCallLogs.length,
                          itemBuilder: (context, index) {
                            final callLog = _filteredCallLogs[index];
                            return CallHistoryCard(
                              callLog: callLog,
                              onTap: () => _showCallDetails(callLog),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
