import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';
import 'reports_list_screen.dart';

enum ReportType { weekly, monthly, custom }

class ReportGenerationScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const ReportGenerationScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  ReportType _selectedReportType = ReportType.weekly;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculateDates();
    _fileNameController.text = '${widget.childName}_${_getReportTypeString()}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
  }

  void _calculateDates() {
    final now = DateTime.now();
    switch (_selectedReportType) {
      case ReportType.weekly:
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case ReportType.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case ReportType.custom:
        // Dates will be selected by user
        break;
    }
  }

  String _getReportTypeString() {
    switch (_selectedReportType) {
      case ReportType.weekly:
        return 'Weekly';
      case ReportType.monthly:
        return 'Monthly';
      case ReportType.custom:
        return 'Custom';
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _generateReport() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date range')),
      );
      return;
    }

    if (_fileNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a file name')),
      );
      return;
    }

    context.read<ReportBloc>().add(
          GenerateReportEvent(
            childId: widget.childId,
            parentId: widget.parentId,
            childName: widget.childName,
            fileName: _fileNameController.text.trim(),
            reportType: _getReportTypeString().toLowerCase(),
            startDate: _startDate!,
            endDate: _endDate!,
          ),
        );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    
    // Get ReportBloc from context, or create new one if not available
    ReportBloc reportBloc;
    try {
      reportBloc = context.read<ReportBloc>();
    } catch (e) {
      // If not available, create new instance
      reportBloc = sl.get<ReportBloc>();
    }

    return BlocProvider.value(
      value: reportBloc,
      child: Scaffold(
        backgroundColor: AppColors.lightCyan,
        appBar: AppBar(
          title: const Text('Generate Report'),
          backgroundColor: AppColors.lightCyan,
          elevation: 0,
          foregroundColor: AppColors.textDark,
        ),
        body: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportGenerated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report generated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            // Get ReportBloc from current context before navigation
            final reportBloc = context.read<ReportBloc>();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (newContext) => BlocProvider.value(
                  value: reportBloc,
                  child: ReportsListScreen(
                    childId: widget.childId,
                    childName: widget.childName,
                    parentId: widget.parentId,
                  ),
                ),
              ),
            );
          } else if (state is ReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mq.w(0.04)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Type Selection
              _buildReportTypeSection(mq),
              SizedBox(height: mq.h(0.03)),

              // Date Range Section
              _buildDateRangeSection(mq),
              SizedBox(height: mq.h(0.03)),

              // File Name Section
              _buildFileNameSection(mq),
              SizedBox(height: mq.h(0.04)),

              // Generate Button
              BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  final isLoading = state is ReportLoading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCyan,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: mq.h(0.02)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Generate Report',
                              style: TextStyle(
                                fontSize: mq.sp(0.05),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildReportTypeSection(MQ mq) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(mq.w(0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Type',
              style: TextStyle(
                fontSize: mq.sp(0.05),
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: mq.h(0.02)),
            ...ReportType.values.map((type) {
              return RadioListTile<ReportType>(
                title: Text(_getReportTypeLabel(type)),
                value: type,
                groupValue: _selectedReportType,
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                    _calculateDates();
                    _fileNameController.text = '${widget.childName}_${_getReportTypeString()}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
                  });
                },
                activeColor: AppColors.darkCyan,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.weekly:
        return 'Weekly (Last 7 days)';
      case ReportType.monthly:
        return 'Monthly (Current month)';
      case ReportType.custom:
        return 'Custom Date Range';
    }
  }

  Widget _buildDateRangeSection(MQ mq) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(mq.w(0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: TextStyle(
                fontSize: mq.sp(0.05),
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: mq.h(0.02)),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.darkCyan),
              title: const Text('Start Date'),
              subtitle: Text(
                _startDate != null
                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                    : 'Select start date',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectStartDate,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.darkCyan),
              title: const Text('End Date'),
              subtitle: Text(
                _endDate != null
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'Select end date',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectEndDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileNameSection(MQ mq) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(mq.w(0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Name',
              style: TextStyle(
                fontSize: mq.sp(0.05),
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: mq.h(0.02)),
            TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                hintText: 'Enter file name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description, color: AppColors.darkCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

