import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/report_data_entity.dart';

class PdfGeneratorService {
  Future<Uint8List> generateReportPdf({
    required String childName,
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    required ReportDataEntity reportData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(childName, reportType, startDate, endDate),
            pw.SizedBox(height: 20),

            // Summary Section
            _buildSummarySection(reportData),
            pw.SizedBox(height: 20),

            // App Usage Chart
            if (reportData.topApps.isNotEmpty) ...[
              _buildAppUsageChart(reportData),
              pw.SizedBox(height: 20),
            ],

            // Top Apps Section
            _buildTopAppsSection(reportData),
            pw.SizedBox(height: 20),

            // Web Usage Chart
            if (reportData.topDomains.isNotEmpty) ...[
              _buildWebUsageChart(reportData),
              pw.SizedBox(height: 20),
            ],

            // Top Domains Section
            _buildTopDomainsSection(reportData),
            pw.SizedBox(height: 20),

            // Location Section
            if (reportData.locationHistory.isNotEmpty) ...[
              _buildLocationSection(reportData),
              pw.SizedBox(height: 20),
            ],

            // Geofence Events Section
            if (reportData.geofenceEvents.isNotEmpty) ...[
              _buildGeofenceSection(reportData),
              pw.SizedBox(height: 20),
            ],

            // Call Logs Section
            if (reportData.callLogs.isNotEmpty) ...[
              _buildCallLogsSection(reportData),
              pw.SizedBox(height: 20),
            ],

            // Messages Section
            if (reportData.messages.isNotEmpty) ...[
              _buildMessagesSection(reportData),
              pw.SizedBox(height: 20),
            ],

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String childName, String reportType, DateTime startDate, DateTime endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Digital Activity Report',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Child: $childName',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Report Type: ${reportType.toUpperCase()}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Period: ${_formatDate(startDate)} - ${_formatDate(endDate)}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSummarySection(ReportDataEntity reportData) {
    final hours = reportData.totalScreenTime ~/ 60;
    final minutes = reportData.totalScreenTime % 60;
    final callHours = reportData.totalCallDuration ~/ 3600;
    final callMinutes = (reportData.totalCallDuration % 3600) ~/ 60;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Screen Time', '${hours}h ${minutes}m'),
              _buildSummaryItem('Apps Used', '${reportData.totalAppsUsed}'),
              _buildSummaryItem('URLs Visited', '${reportData.totalUrlsVisited}'),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Location Updates', '${reportData.totalLocationUpdates}'),
              _buildSummaryItem('Geofence Events', '${reportData.totalGeofenceExits + reportData.totalGeofenceEntries}'),
              _buildSummaryItem('Calls', '${reportData.totalCalls}'),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Call Duration', '${callHours}h ${callMinutes}m'),
              _buildSummaryItem('Messages', '${reportData.totalMessages}'),
              _buildSummaryItem('Flagged', '${reportData.flaggedMessages}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildAppUsageChart(ReportDataEntity reportData) {
    if (reportData.topApps.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final maxMinutes = reportData.topApps.isNotEmpty
        ? reportData.topApps.map((app) => app['minutes'] as int).reduce(math.max)
        : 1;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'App Usage Chart',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          height: 200,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: reportData.topApps.take(5).map((app) {
              final minutes = app['minutes'] as int;
              final height = (minutes / maxMinutes) * 180;
              
              return pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      height: height,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue700,
                        borderRadius: const pw.BorderRadius.vertical(
                          top: pw.Radius.circular(5),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${minutes}m',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _truncateAppName(app['appName'] as String),
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildWebUsageChart(ReportDataEntity reportData) {
    if (reportData.topDomains.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final maxCount = reportData.topDomains.isNotEmpty
        ? reportData.topDomains.map((domain) => domain['count'] as int).reduce(math.max)
        : 1;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Web Usage Chart',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          height: 200,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: reportData.topDomains.take(5).map((domain) {
              final count = domain['count'] as int;
              final height = (count / maxCount) * 180;
              
              return pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      height: height,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green700,
                        borderRadius: const pw.BorderRadius.vertical(
                          top: pw.Radius.circular(5),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '$count',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _truncateDomain(domain['domain'] as String),
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _truncateAppName(String name) {
    if (name.length <= 10) return name;
    return '${name.substring(0, 8)}...';
  }

  String _truncateDomain(String domain) {
    if (domain.length <= 12) return domain;
    return '${domain.substring(0, 10)}...';
  }

  pw.Widget _buildTopAppsSection(ReportDataEntity reportData) {
    if (reportData.topApps.isEmpty) {
      return pw.Text(
        'No app usage data available',
        style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Apps by Usage',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('App Name', isHeader: true),
                _buildTableCell('Usage (min)', isHeader: true),
                _buildTableCell('Percentage', isHeader: true),
              ],
            ),
            ...reportData.topApps.map((app) {
              final minutes = app['minutes'] as int;
              final percentage = app['percentage'] as String;
              return pw.TableRow(
                children: [
                  _buildTableCell(app['appName'] as String),
                  _buildTableCell('$minutes'),
                  _buildTableCell('$percentage%'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTopDomainsSection(ReportDataEntity reportData) {
    if (reportData.topDomains.isEmpty) {
      return pw.Text(
        'No browsing data available',
        style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Visited Domains',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Domain', isHeader: true),
                _buildTableCell('Visits', isHeader: true),
                _buildTableCell('Percentage', isHeader: true),
              ],
            ),
            ...reportData.topDomains.map((domain) {
              final count = domain['count'] as int;
              final percentage = domain['percentage'] as String;
              return pw.TableRow(
                children: [
                  _buildTableCell(domain['domain'] as String),
                  _buildTableCell('$count'),
                  _buildTableCell('$percentage%'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildLocationSection(ReportDataEntity reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Location History',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Total Location Updates: ${reportData.totalLocationUpdates}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Time', isHeader: true),
                _buildTableCell('Address', isHeader: true),
                _buildTableCell('Coordinates', isHeader: true),
              ],
            ),
            ...reportData.locationHistory.take(10).map((location) {
              final timestamp = location['timestamp'];
              final address = location['address'] ?? 'Unknown';
              final lat = location['latitude'] ?? 0.0;
              final lng = location['longitude'] ?? 0.0;
              String timeStr = 'Unknown';
              if (timestamp != null) {
                try {
                  final date = (timestamp as Timestamp).toDate();
                  timeStr = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                } catch (e) {
                  timeStr = 'N/A';
                }
              }
              return pw.TableRow(
                children: [
                  _buildTableCell(timeStr),
                  _buildTableCell(address.length > 30 ? '${address.substring(0, 30)}...' : address),
                  _buildTableCell('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGeofenceSection(ReportDataEntity reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Geofence Events',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Entries', '${reportData.totalGeofenceEntries}'),
            _buildSummaryItem('Exits', '${reportData.totalGeofenceExits}'),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Time', isHeader: true),
                _buildTableCell('Zone', isHeader: true),
                _buildTableCell('Event', isHeader: true),
              ],
            ),
            ...reportData.geofenceEvents.take(15).map((event) {
              final timestamp = event['occurredAt'];
              final zoneName = event['zoneName'] ?? 'Unknown';
              final eventType = event['eventType'] ?? 'exit';
              String timeStr = 'Unknown';
              if (timestamp != null) {
                try {
                  final date = (timestamp as Timestamp).toDate();
                  timeStr = '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                } catch (e) {
                  timeStr = 'N/A';
                }
              }
              return pw.TableRow(
                children: [
                  _buildTableCell(timeStr),
                  _buildTableCell(zoneName),
                  _buildTableCell(eventType == 'enter' ? 'Entered' : 'Exited'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCallLogsSection(ReportDataEntity reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Call Logs',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Total Calls: ${reportData.totalCalls}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Time', isHeader: true),
                _buildTableCell('Contact', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Duration', isHeader: true),
              ],
            ),
            ...reportData.callLogs.take(15).map((call) {
              final dateTime = call['dateTime'] as int?;
              final name = call['name'] ?? 'Unknown';
              final number = call['number'] ?? 'Unknown';
              final type = call['type'] ?? 'unknown';
              final duration = call['duration'] ?? 0;
              String timeStr = 'Unknown';
              if (dateTime != null) {
                try {
                  final date = DateTime.fromMillisecondsSinceEpoch(dateTime);
                  timeStr = '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                } catch (e) {
                  timeStr = 'N/A';
                }
              }
              final durationStr = duration > 0 ? '${duration}s' : '0s';
              return pw.TableRow(
                children: [
                  _buildTableCell(timeStr),
                  _buildTableCell(name != 'Unknown' ? name : number),
                  _buildTableCell(type.toString().replaceAll('CallType.', '')),
                  _buildTableCell(durationStr),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMessagesSection(ReportDataEntity reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Messages',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total Messages', '${reportData.totalMessages}'),
            _buildSummaryItem('Flagged', '${reportData.flaggedMessages}'),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Time', isHeader: true),
                _buildTableCell('Type', isHeader: true),
                _buildTableCell('Content', isHeader: true),
                _buildTableCell('Flagged', isHeader: true),
              ],
            ),
            ...reportData.messages.take(15).map((message) {
              final timestamp = message['timestamp'];
              final type = message['type'] ?? 'text';
              final content = message['content'] ?? '';
              final flagged = message['flagged'] == true;
              String timeStr = 'Unknown';
              if (timestamp != null) {
                try {
                  final date = (timestamp as Timestamp).toDate();
                  timeStr = '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                } catch (e) {
                  timeStr = 'N/A';
                }
              }
              final contentPreview = content.length > 30 ? '${content.substring(0, 30)}...' : content;
              return pw.TableRow(
                children: [
                  _buildTableCell(timeStr),
                  _buildTableCell(type),
                  _buildTableCell(contentPreview),
                  _buildTableCell(flagged ? 'Yes' : 'No'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        'Generated on ${_formatDate(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
