import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../url_tracking/data/models/visited_url_firebase.dart';
import '../../domain/entities/report_data_entity.dart';

class ReportDataModel {
  final List<AppUsageFirebase> appUsage;
  final List<VisitedUrlFirebase> visitedUrls;
  final int totalScreenTime; // in minutes
  final Map<String, int> appUsageByApp; // appName -> minutes
  final Map<String, int> urlVisitsByDomain; // domain -> count
  final int totalUrlsVisited;
  final int totalAppsUsed;
  final List<Map<String, dynamic>> topApps; // [{appName, minutes, percentage}]
  final List<Map<String, dynamic>> topDomains; // [{domain, count, percentage}]
  
  // Location data
  final List<Map<String, dynamic>> locationHistory;
  final int totalLocationUpdates;
  
  // Geofence events
  final List<Map<String, dynamic>> geofenceEvents;
  final int totalGeofenceExits;
  final int totalGeofenceEntries;
  
  // Call logs
  final List<Map<String, dynamic>> callLogs;
  final int totalCalls;
  final int totalCallDuration; // in seconds
  
  // Messages
  final List<Map<String, dynamic>> messages;
  final int totalMessages;
  final int flaggedMessages;

  ReportDataModel({
    required this.appUsage,
    required this.visitedUrls,
    required this.totalScreenTime,
    required this.appUsageByApp,
    required this.urlVisitsByDomain,
    required this.totalUrlsVisited,
    required this.totalAppsUsed,
    required this.topApps,
    required this.topDomains,
    this.locationHistory = const [],
    this.totalLocationUpdates = 0,
    this.geofenceEvents = const [],
    this.totalGeofenceExits = 0,
    this.totalGeofenceEntries = 0,
    this.callLogs = const [],
    this.totalCalls = 0,
    this.totalCallDuration = 0,
    this.messages = const [],
    this.totalMessages = 0,
    this.flaggedMessages = 0,
  });

  ReportDataEntity toEntity() {
    return ReportDataEntity(
      totalScreenTime: totalScreenTime,
      appUsageByApp: appUsageByApp,
      urlVisitsByDomain: urlVisitsByDomain,
      totalUrlsVisited: totalUrlsVisited,
      totalAppsUsed: totalAppsUsed,
      topApps: topApps,
      topDomains: topDomains,
      locationHistory: locationHistory,
      totalLocationUpdates: totalLocationUpdates,
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
  }

  Map<String, dynamic> toJson() {
    return {
      'totalScreenTime': totalScreenTime,
      'totalUrlsVisited': totalUrlsVisited,
      'totalAppsUsed': totalAppsUsed,
      'appUsageByApp': appUsageByApp,
      'urlVisitsByDomain': urlVisitsByDomain,
      'topApps': topApps,
      'topDomains': topDomains,
      'locationHistory': locationHistory,
      'totalLocationUpdates': totalLocationUpdates,
      'geofenceEvents': geofenceEvents,
      'totalGeofenceExits': totalGeofenceExits,
      'totalGeofenceEntries': totalGeofenceEntries,
      'callLogs': callLogs,
      'totalCalls': totalCalls,
      'totalCallDuration': totalCallDuration,
      'messages': messages,
      'totalMessages': totalMessages,
      'flaggedMessages': flaggedMessages,
    };
  }
}

