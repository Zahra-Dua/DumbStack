import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/geofence_remote_datasource.dart';
import '../models/geofence_zone_model.dart';
import '../models/zone_event_model.dart';
import '../../domain/entities/zone_event_entity.dart';
import '../../../notifications/data/services/notification_integration_service.dart';

/// Service to detect geofencing entry/exit and send notifications
class GeofencingDetectionService {
  final GeofenceRemoteDataSource _geofenceDataSource;
  final NotificationIntegrationService _notificationService;
  
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<GeofenceZoneModel>>? _geofenceStream;
  Timer? _checkTimer;
  
  String? _parentId;
  String? _childId;
  bool _isMonitoring = false;
  
  // Track which zones child is currently inside
  final Map<String, bool> _currentZoneStatus = {};
  List<GeofenceZoneModel> _activeGeofences = [];

  GeofencingDetectionService({
    required GeofenceRemoteDataSource geofenceDataSource,
    NotificationIntegrationService? notificationService,
  }) : _geofenceDataSource = geofenceDataSource,
       _notificationService = notificationService ?? NotificationIntegrationService();

  /// Initialize and start geofencing monitoring
  Future<void> startGeofencingMonitoring() async {
    if (_isMonitoring) {
      print('⚠️ Geofencing monitoring already active');
      return;
    }

    try {
      // Get parent and child IDs
      final prefs = await SharedPreferences.getInstance();
      _parentId = prefs.getString('parent_uid');
      _childId = prefs.getString('child_uid');

      if (_parentId == null || _childId == null) {
        print('❌ Parent or child ID not found');
        return;
      }

      print('🚀 Starting geofencing monitoring for child: $_childId');

      // Request location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      _isMonitoring = true;

      // Stream geofences for this child
      _geofenceStream = _geofenceDataSource.streamGeofenceZones(_childId!).listen(
        (geofences) {
          _activeGeofences = geofences.where((g) => g.isActive).toList();
          print('📍 Active geofences updated: ${_activeGeofences.length}');
          
          // Initialize zone status
          for (var zone in _activeGeofences) {
            if (!_currentZoneStatus.containsKey(zone.id)) {
              _currentZoneStatus[zone.id] = false;
            }
          }
        },
        onError: (error) => print('❌ Error streaming geofences: $error'),
      );

      // Start location monitoring with high accuracy and frequent updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Check every 5 meters movement
        ),
      ).listen(
        (Position position) => _checkGeofences(position),
        onError: (error) => print('❌ Location stream error: $error'),
      );

      // Also check periodically (every 10 seconds) as backup
      _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          _checkGeofences(position);
        } catch (e) {
          print('⚠️ Error getting current position: $e');
        }
      });

      print('✅ Geofencing monitoring started');
    } catch (e) {
      print('❌ Error starting geofencing monitoring: $e');
      _isMonitoring = false;
    }
  }

  /// Stop geofencing monitoring
  Future<void> stopGeofencingMonitoring() async {
    if (!_isMonitoring) return;

    print('🛑 Stopping geofencing monitoring...');
    _isMonitoring = false;

    await _positionStream?.cancel();
    _positionStream = null;

    await _geofenceStream?.cancel();
    _geofenceStream = null;

    _checkTimer?.cancel();
    _checkTimer = null;

    _currentZoneStatus.clear();
    _activeGeofences.clear();

    print('✅ Geofencing monitoring stopped');
  }

  /// Check current position against all active geofences
  Future<void> _checkGeofences(Position position) async {
    if (!_isMonitoring || _parentId == null || _childId == null) {
      return;
    }

    if (_activeGeofences.isEmpty) {
      return; // No geofences to check
    }

    try {
      for (var zone in _activeGeofences) {
        final wasInside = _currentZoneStatus[zone.id] ?? false;
        final isInside = zone.containsLocation(
          position.latitude,
          position.longitude,
        );

        // Update current status
        _currentZoneStatus[zone.id] = isInside;

        // Detect entry
        if (!wasInside && isInside) {
          print('🟢 Child entered zone: ${zone.name}');
          await _handleZoneEntry(zone, position);
        }
        // Detect exit
        else if (wasInside && !isInside) {
          print('🔴 Child exited zone: ${zone.name}');
          await _handleZoneExit(zone, position);
        }
      }
    } catch (e) {
      print('❌ Error checking geofences: $e');
    }
  }

  /// Handle zone entry
  Future<void> _handleZoneEntry(
    GeofenceZoneModel zone,
    Position position,
  ) async {
    try {
      // Create zone event
      final event = ZoneEventModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        childId: _childId!,
        zoneId: zone.id,
        zoneName: zone.name,
        eventType: ZoneEventType.enter,
        childLatitude: position.latitude,
        childLongitude: position.longitude,
        occurredAt: DateTime.now(),
        isNotified: false,
        deviceSource: 'device',
      );

      // Save to Firestore
      await _geofenceDataSource.createZoneEvent(event);
      print('✅ Zone entry event saved');

      // Send FCM notification to parent
      await _notificationService.onGeofencingEvent(
        parentId: _parentId!,
        childId: _childId!,
        zoneName: zone.name,
        eventType: 'entry',
        latitude: position.latitude,
        longitude: position.longitude,
        address: null, // Could be geocoded if needed
      );
      print('✅ Entry notification sent to parent');
    } catch (e) {
      print('❌ Error handling zone entry: $e');
    }
  }

  /// Handle zone exit
  Future<void> _handleZoneExit(
    GeofenceZoneModel zone,
    Position position,
  ) async {
    try {
      // Create zone event
      final event = ZoneEventModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        childId: _childId!,
        zoneId: zone.id,
        zoneName: zone.name,
        eventType: ZoneEventType.exit,
        childLatitude: position.latitude,
        childLongitude: position.longitude,
        occurredAt: DateTime.now(),
        isNotified: false,
        deviceSource: 'device',
      );

      // Save to Firestore
      await _geofenceDataSource.createZoneEvent(event);
      print('✅ Zone exit event saved');

      // Send FCM notification to parent
      await _notificationService.onGeofencingEvent(
        parentId: _parentId!,
        childId: _childId!,
        zoneName: zone.name,
        eventType: 'exit',
        latitude: position.latitude,
        longitude: position.longitude,
        address: null, // Could be geocoded if needed
      );
      print('✅ Exit notification sent to parent');
    } catch (e) {
      print('❌ Error handling zone exit: $e');
    }
  }

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Dispose resources
  void dispose() {
    stopGeofencingMonitoring();
  }
}

