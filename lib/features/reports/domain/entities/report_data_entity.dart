import 'package:equatable/equatable.dart';

class ReportDataEntity extends Equatable {
  final int totalScreenTime; // in minutes
  final Map<String, int> appUsageByApp; // appName -> minutes
  final Map<String, int> urlVisitsByDomain; // domain -> count
  final int totalUrlsVisited;
  final int totalAppsUsed;
  final List<Map<String, dynamic>> topApps; // [{appName, minutes, percentage}]
  final List<Map<String, dynamic>> topDomains; // [{domain, count, percentage}]
  
  // Location data
  final List<Map<String, dynamic>> locationHistory; // [{latitude, longitude, address, timestamp}]
  final int totalLocationUpdates;
  
  // Geofence events
  final List<Map<String, dynamic>> geofenceEvents; // [{zoneName, eventType, occurredAt, address}]
  final int totalGeofenceExits;
  final int totalGeofenceEntries;
  
  // Call logs
  final List<Map<String, dynamic>> callLogs; // [{number, name, type, duration, dateTime}]
  final int totalCalls;
  final int totalCallDuration; // in seconds
  
  // Messages
  final List<Map<String, dynamic>> messages; // [{content, type, timestamp, flagged}]
  final int totalMessages;
  final int flaggedMessages;

  const ReportDataEntity({
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

  @override
  List<Object?> get props => [
        totalScreenTime,
        appUsageByApp,
        urlVisitsByDomain,
        totalUrlsVisited,
        totalAppsUsed,
        topApps,
        topDomains,
        locationHistory,
        totalLocationUpdates,
        geofenceEvents,
        totalGeofenceExits,
        totalGeofenceEntries,
        callLogs,
        totalCalls,
        totalCallDuration,
        messages,
        totalMessages,
        flaggedMessages,
      ];
}

