import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/call_log_model.dart';
import '../../data/datasources/flagged_calls_remote_datasource.dart';
import '../widgets/call_history_card.dart';

class FlaggedCallsScreen extends StatefulWidget {
  final String parentId;
  final String childId;
  final String childName;

  const FlaggedCallsScreen({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
  });

  @override
  State<FlaggedCallsScreen> createState() => _FlaggedCallsScreenState();
}

class _FlaggedCallsScreenState extends State<FlaggedCallsScreen> {
  final FlaggedCallsRemoteDataSource _dataSource =
      FlaggedCallsRemoteDataSource(firestore: FirebaseFirestore.instance);
  List<CallLogModel> _flaggedCalls = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  StreamSubscription<List<CallLogModel>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _loadFlaggedCalls();
    _startListening();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// Start listening to real-time flagged calls stream
  void _startListening() {
    _streamSubscription = _dataSource.getFlaggedCallsStream(
      parentId: widget.parentId,
      childId: widget.childId,
    ).listen(
      (calls) {
        if (mounted) {
          setState(() {
            _flaggedCalls = _dedupeAndSort(calls);
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        print('❌ [FlaggedCalls] Stream error: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  /// Manual refresh
  Future<void> _loadFlaggedCalls() async {
    setState(() => _isLoading = true);

    try {
      print('🚨 [FlaggedCalls] Loading flagged calls...');
      final flaggedCalls = await _dataSource.getFlaggedCalls(
        parentId: widget.parentId,
        childId: widget.childId,
      );

      setState(() {
        _flaggedCalls = _dedupeAndSort(flaggedCalls);
        _isLoading = false;
      });

      print('✅ [FlaggedCalls] Loaded ${_flaggedCalls.length} flagged calls');
    } catch (e) {
      print('❌ [FlaggedCalls] Error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading flagged calls: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<CallLogModel> get _filteredFlaggedCalls {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final calls24h = _flaggedCalls.where((c) => c.dateTime.isAfter(last24h));

    if (_selectedFilter == 'All') return calls24h.toList();

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

    return calls24h.where((c) => c.type == filterType).toList();
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
        title: Text('${widget.childName}\'s Flagged Calls', style: const TextStyle(color: AppColors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFlaggedCalls)],
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
                        selectedColor: AppColors.error.withOpacity(0.2),
                        checkmarkColor: AppColors.error,
                        labelStyle: TextStyle(color: isSelected ? AppColors.error : AppColors.textDark, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Flagged Calls List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.error)))
                  : _filteredFlaggedCalls.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_end, size: 64, color: Colors.grey[400]),
                              SizedBox(height: mq.h(0.02)),
                              Text('No flagged calls found', style: TextStyle(fontSize: mq.sp(0.05), color: Colors.grey[600], fontWeight: FontWeight.w500)),
                              SizedBox(height: mq.h(0.01)),
                              Text('Suspicious calls will appear here', style: TextStyle(fontSize: mq.sp(0.04), color: Colors.grey[500]), textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: mq.h(0.01)),
                          itemCount: _filteredFlaggedCalls.length,
                          itemBuilder: (context, index) {
                            final callLog = _filteredFlaggedCalls[index];
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

