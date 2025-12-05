import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';
import 'report_generation_screen.dart';

class ReportsListScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const ReportsListScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportBloc>().add(
              GetReportsEvent(
                childId: widget.childId,
                parentId: widget.parentId,
              ),
            );
      }
    });
  }

  Future<void> _openReport(String? localPath) async {
    if (localPath == null || localPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report file not found')),
      );
      return;
    }

    try {
      final file = File(localPath);
      if (await file.exists()) {
        final pdfBytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report file not found on device')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening report: $e')),
      );
    }
  }

  Future<void> _shareReport(String? localPath) async {
    if (localPath == null || localPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report file not found')),
      );
      return;
    }

    try {
      final file = File(localPath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(localPath)]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report file not found on device')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing report: $e')),
      );
    }
  }

  void _deleteReport(String reportId, String? localPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ReportBloc>().add(
                    DeleteReportEvent(
                      childId: widget.childId,
                      parentId: widget.parentId,
                      reportId: reportId,
                      localPath: localPath,
                    ),
                  );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _renameReport(report) {
    final TextEditingController controller = TextEditingController(text: report.fileName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Report'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Report Name',
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != report.fileName) {
                Navigator.pop(context);
                context.read<ReportBloc>().add(
                      RenameReportEvent(
                        childId: widget.childId,
                        parentId: widget.parentId,
                        reportId: report.id,
                        oldFileName: report.fileName,
                        newFileName: newName,
                        localPath: report.localPath,
                      ),
                    );
              }
            },
            child: const Text('Rename'),
          ),
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
        title: Text('${widget.childName}\'s Reports'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Get ReportBloc from current context
              final reportBloc = context.read<ReportBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (newContext) => BlocProvider.value(
                    value: reportBloc,
                    child: ReportGenerationScreen(
                      childId: widget.childId,
                      childName: widget.childName,
                      parentId: widget.parentId,
                    ),
                  ),
                ),
              );
            },
            tooltip: 'Generate New Report',
          ),
        ],
      ),
      body: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ReportRenamed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report renamed successfully'),
                backgroundColor: AppColors.success,
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
        child: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is ReportsListLoaded) {
              if (state.reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 80,
                        color: AppColors.textLight,
                      ),
                      SizedBox(height: mq.h(0.02)),
                      Text(
                        'No reports generated yet',
                        style: TextStyle(
                          fontSize: mq.sp(0.05),
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: mq.h(0.02)),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Get ReportBloc from current context
                          final reportBloc = context.read<ReportBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (newContext) => BlocProvider.value(
                                value: reportBloc,
                                child: ReportGenerationScreen(
                                  childId: widget.childId,
                                  childName: widget.childName,
                                  parentId: widget.parentId,
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Generate First Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkCyan,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ReportBloc>().add(
                        GetReportsEvent(
                          childId: widget.childId,
                          parentId: widget.parentId,
                        ),
                      );
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(mq.w(0.04)),
                  itemCount: state.reports.length,
                  itemBuilder: (context, index) {
                    final report = state.reports[index];
                    return _buildReportCard(mq, report);
                  },
                ),
              );
            } else if (state is ReportError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppColors.error,
                    ),
                    SizedBox(height: mq.h(0.02)),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: mq.h(0.02)),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ReportBloc>().add(
                              GetReportsEvent(
                                childId: widget.childId,
                                parentId: widget.parentId,
                              ),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildReportCard(MQ mq, report) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: mq.h(0.02)),
      child: Padding(
        padding: EdgeInsets.all(mq.w(0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: AppColors.darkCyan,
                    size: 24,
                  ),
                ),
                SizedBox(width: mq.w(0.03)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.fileName,
                        style: TextStyle(
                          fontSize: mq.sp(0.05),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: mq.h(0.005)),
                      Text(
                        '${report.reportType.toUpperCase()} Report',
                        style: TextStyle(
                          fontSize: mq.sp(0.04),
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.open_in_new, color: AppColors.darkCyan),
                          SizedBox(width: 8),
                          Text('Open'),
                        ],
                      ),
                      onTap: () => _openReport(report.localPath),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.share, color: AppColors.darkCyan),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                      onTap: () => _shareReport(report.localPath),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.darkCyan),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                      onTap: () => _renameReport(report),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                      onTap: () => _deleteReport(report.id, report.localPath),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: mq.h(0.02)),
            Divider(color: AppColors.border),
            SizedBox(height: mq.h(0.01)),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textLight),
                SizedBox(width: mq.w(0.02)),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(report.startDate)} - ${DateFormat('dd/MM/yyyy').format(report.endDate)}',
                  style: TextStyle(
                    fontSize: mq.sp(0.04),
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: mq.h(0.01)),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                SizedBox(width: mq.w(0.02)),
                Text(
                  'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(report.generatedAt)}',
                  style: TextStyle(
                    fontSize: mq.sp(0.04),
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
