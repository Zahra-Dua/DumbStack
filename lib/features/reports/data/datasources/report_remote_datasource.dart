import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/report_model.dart';
import '../models/report_data_model.dart';
import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../url_tracking/data/models/visited_url_firebase.dart';

abstract class ReportRemoteDataSource {
  Future<ReportDataModel> fetchReportData({
    required String childId,
    required String parentId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<String> saveReportLocally({
    required String fileName,
    required List<int> pdfBytes,
  });

  Future<void> saveReportMetadata({
    required ReportModel report,
  });

  Future<List<ReportModel>> getReports({
    required String childId,
    required String parentId,
  });

  Future<void> deleteReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String? localPath,
  });

  Future<void> renameReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String oldFileName,
    required String newFileName,
    required String? localPath,
  });

  Future<File?> getReportFile(String localPath);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore firestore;

  ReportRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<ReportDataModel> fetchReportData({
    required String childId,
    required String parentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final endDateWithTime = endDate.add(const Duration(days: 1));
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDateWithTime);

      // Fetch app usage data
      final appUsageSnapshot = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('appUsage')
          .where('lastUsed', isGreaterThanOrEqualTo: startTimestamp)
          .where('lastUsed', isLessThanOrEqualTo: endTimestamp)
          .get();

      final appUsage = appUsageSnapshot.docs
          .map((doc) => AppUsageFirebase.fromJson(doc.data()))
          .toList();

      // Fetch visited URLs
      final urlsSnapshot = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .where('visitedAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('visitedAt', isLessThanOrEqualTo: endTimestamp)
          .get();

      final visitedUrls = urlsSnapshot.docs
          .map((doc) => VisitedUrlFirebase.fromJson(doc.data()))
          .toList();

      // Fetch location history
      List<Map<String, dynamic>> locationHistory = [];
      try {
        final locationSnapshot = await firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('location')
            .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
            .where('timestamp', isLessThanOrEqualTo: endTimestamp)
            .orderBy('timestamp', descending: true)
            .get();

        locationHistory = locationSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'latitude': data['latitude'] ?? 0.0,
            'longitude': data['longitude'] ?? 0.0,
            'address': data['address'] ?? 'Unknown',
            'timestamp': data['timestamp'],
            'accuracy': data['accuracy'] ?? 0.0,
          };
        }).toList();
      } catch (e) {
        print('Error fetching location history: $e');
      }

      // Fetch geofence events
      List<Map<String, dynamic>> geofenceEvents = [];
      int totalGeofenceExits = 0;
      int totalGeofenceEntries = 0;
      try {
        final geofenceSnapshot = await firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('zoneEvents')
            .where('occurredAt', isGreaterThanOrEqualTo: startTimestamp)
            .where('occurredAt', isLessThanOrEqualTo: endTimestamp)
            .orderBy('occurredAt', descending: true)
            .get();

        geofenceEvents = geofenceSnapshot.docs.map((doc) {
          final data = doc.data();
          final eventType = data['eventType'] ?? 'exit';
          if (eventType == 'exit') {
            totalGeofenceExits++;
          } else {
            totalGeofenceEntries++;
          }
          return {
            'zoneName': data['zoneName'] ?? 'Unknown Zone',
            'eventType': eventType,
            'occurredAt': data['occurredAt'],
            'latitude': data['childLatitude'] ?? 0.0,
            'longitude': data['childLongitude'] ?? 0.0,
          };
        }).toList();
      } catch (e) {
        print('Error fetching geofence events: $e');
      }

      // Fetch call logs
      List<Map<String, dynamic>> callLogs = [];
      int totalCalls = 0;
      int totalCallDuration = 0;
      try {
        final callLogsSnapshot = await firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('call_logs')
            .where('dateTime', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch)
            .where('dateTime', isLessThanOrEqualTo: endDateWithTime.millisecondsSinceEpoch)
            .orderBy('dateTime', descending: true)
            .get();

        callLogs = callLogsSnapshot.docs.map((doc) {
          final data = doc.data();
          totalCalls++;
          totalCallDuration += (data['duration'] ?? 0) as int;
          return {
            'number': data['number'] ?? 'Unknown',
            'name': data['name'] ?? 'Unknown',
            'type': data['type'] ?? 'unknown',
            'duration': data['duration'] ?? 0,
            'dateTime': data['dateTime'],
          };
        }).toList();
      } catch (e) {
        print('Error fetching call logs: $e');
      }

      // Fetch messages
      List<Map<String, dynamic>> messages = [];
      int totalMessages = 0;
      int flaggedMessages = 0;
      try {
        final messagesSnapshot = await firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('messages')
            .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
            .where('timestamp', isLessThanOrEqualTo: endTimestamp)
            .orderBy('timestamp', descending: true)
            .get();

        messages = messagesSnapshot.docs.map((doc) {
          final data = doc.data();
          totalMessages++;
          if (data['flag'] == true || data['isFlagged'] == true) {
            flaggedMessages++;
          }
          return {
            'content': data['content'] ?? '',
            'type': data['messageType'] ?? 'text',
            'timestamp': data['timestamp'],
            'flagged': data['flag'] == true || data['isFlagged'] == true,
            'sender': data['senderId'] ?? 'Unknown',
          };
        }).toList();
      } catch (e) {
        print('Error fetching messages: $e');
      }

      // Aggregate app usage
      final Map<String, int> appUsageByApp = {};
      int totalScreenTime = 0;

      for (var app in appUsage) {
        final appName = app.appName;
        final minutes = app.usageDuration;
        appUsageByApp[appName] = (appUsageByApp[appName] ?? 0) + minutes;
        totalScreenTime += minutes;
      }

      // Aggregate URL visits by domain
      final Map<String, int> urlVisitsByDomain = {};
      for (var url in visitedUrls) {
        try {
          final uri = Uri.parse(url.url);
          final domain = uri.host;
          urlVisitsByDomain[domain] = (urlVisitsByDomain[domain] ?? 0) + 1;
        } catch (e) {
          // Skip invalid URLs
        }
      }

      // Calculate top apps
      final appEntries = appUsageByApp.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topApps = appEntries.take(10).map((entry) {
        final percentage = totalScreenTime > 0
            ? (entry.value / totalScreenTime * 100).toStringAsFixed(1)
            : '0.0';
        return {
          'appName': entry.key,
          'minutes': entry.value,
          'percentage': percentage,
        };
      }).toList();

      // Calculate top domains
      final domainEntries = urlVisitsByDomain.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topDomains = domainEntries.take(10).map((entry) {
        final percentage = visitedUrls.isNotEmpty
            ? (entry.value / visitedUrls.length * 100).toStringAsFixed(1)
            : '0.0';
        return {
          'domain': entry.key,
          'count': entry.value,
          'percentage': percentage,
        };
      }).toList();

      return ReportDataModel(
        appUsage: appUsage,
        visitedUrls: visitedUrls,
        totalScreenTime: totalScreenTime,
        appUsageByApp: appUsageByApp,
        urlVisitsByDomain: urlVisitsByDomain,
        totalUrlsVisited: visitedUrls.length,
        totalAppsUsed: appUsageByApp.length,
        topApps: topApps,
        topDomains: topDomains,
        locationHistory: locationHistory,
        totalLocationUpdates: locationHistory.length,
        geofenceEvents: geofenceEvents,
        totalGeofenceExits: totalGeofenceExits,
        totalGeofenceEntries: totalGeofenceEntries,
        callLogs: callLogs,
        totalCalls: totalCalls,
        totalCallDuration: totalCallDuration,
        messages: messages,
        totalMessages: totalMessages,
        flaggedMessages: flaggedMessages,
      );
    } catch (e) {
      throw Exception('Error fetching report data: $e');
    }
  }

  @override
  Future<String> saveReportLocally({
    required String fileName,
    required List<int> pdfBytes,
  }) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      
      // Create reports directory if it doesn't exist
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      // Save PDF file
      final file = File('${reportsDir.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);

      return file.path;
    } catch (e) {
      throw Exception('Error saving report locally: $e');
    }
  }

  @override
  Future<void> saveReportMetadata({
    required ReportModel report,
  }) async {
    try {
      await firestore
          .collection('parents')
          .doc(report.parentId)
          .collection('children')
          .doc(report.childId)
          .collection('reports')
          .doc(report.id)
          .set(report.toJson());
    } catch (e) {
      throw Exception('Error saving report metadata: $e');
    }
  }

  @override
  Future<List<ReportModel>> getReports({
    required String childId,
    required String parentId,
  }) async {
    try {
      final snapshot = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('reports')
          .orderBy('generatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  @override
  Future<void> deleteReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String? localPath,
  }) async {
    try {
      // Delete from Firestore
      await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('reports')
          .doc(reportId)
          .delete();

      // Delete local file if path exists
      if (localPath != null && localPath.isNotEmpty) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      throw Exception('Error deleting report: $e');
    }
  }

  @override
  Future<void> renameReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String oldFileName,
    required String newFileName,
    required String? localPath,
  }) async {
    try {
      // Update Firestore metadata
      await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('reports')
          .doc(reportId)
          .update({'fileName': newFileName});

      // Rename local file if path exists
      if (localPath != null && localPath.isNotEmpty) {
        final oldFile = File(localPath);
        if (await oldFile.exists()) {
          final directory = oldFile.parent;
          final newFile = File('${directory.path}/$newFileName.pdf');
          await oldFile.rename(newFile.path);
        }
      }
    } catch (e) {
      throw Exception('Error renaming report: $e');
    }
  }

  @override
  Future<File?> getReportFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
