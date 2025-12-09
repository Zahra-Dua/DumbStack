import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/location_model.dart';
import '../datasources/location_remote_datasource.dart';

class ChildLocationService {
  final LocationRemoteDataSource _locationDataSource;
  final FirebaseFirestore _firestore;
  
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<BatteryState>? _batteryStream;
  Timer? _locationTimer;
  Timer? _batteryTimer;
  String? _parentId;
  String? _childId;
  bool _isTracking = false;
  final Battery _battery = Battery();

  ChildLocationService({
    required LocationRemoteDataSource locationDataSource,
    FirebaseFirestore? firestore,
  }) : _locationDataSource = locationDataSource,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize location tracking for child
  Future<void> initializeLocationTracking() async {
    try {
      // Get parent and child IDs from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _parentId = prefs.getString('parent_uid');
      _childId = prefs.getString('child_uid');

      if (_parentId == null || _childId == null) {
        print('Parent or child ID not found in SharedPreferences');
        return;
      }

      print('Initialized location tracking for child: $_childId');
    } catch (e) {
      print('Error initializing location tracking: $e');
    }
  }

  /// Start location tracking
  Future<void> startLocationTracking() async {
    if (_parentId == null || _childId == null) {
      await initializeLocationTracking();
      if (_parentId == null || _childId == null) {
        throw Exception('Parent or child ID not found');
      }
    }

    // Check if already tracking
    if (_isTracking) {
      print('Location tracking already active');
      return;
    }

    try {
      print('Starting location tracking...');
      _isTracking = true;

      // Request location permission
      print('📍 [ChildLocation] Checking location permission...');
      final permission = await Geolocator.checkPermission();
      print('📍 [ChildLocation] Current permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 [ChildLocation] Permission denied, requesting...');
        final newPermission = await Geolocator.requestPermission();
        print('📍 [ChildLocation] Permission request result: $newPermission');
        if (newPermission == LocationPermission.denied || newPermission == LocationPermission.deniedForever) {
          print('❌ [ChildLocation] Location permission denied or denied forever');
          throw Exception('Location permission denied');
        }
      }
      
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ [ChildLocation] Location services are disabled');
        throw Exception('Location services are disabled. Please enable location in device settings.');
      }
      print('✅ [ChildLocation] Location services enabled');

      // Enable location services
      await _locationDataSource.enableLocationTracking(
        parentId: _parentId!,
        childId: _childId!,
        enabled: true,
      );

      // Start listening to location updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (Position position) => _onLocationUpdate(position),
        onError: (error) => print('Location stream error: $error'),
      );

      // Start battery tracking
      _startBatteryTracking();

      print('Location tracking started for child: $_childId');
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    try {
      print('Stopping location tracking...');
      _isTracking = false;
      
      // Cancel position stream
      await _positionStream?.cancel();
      _positionStream = null;
      
      // Cancel timer
      _locationTimer?.cancel();
      _locationTimer = null;
      
      // Update Firebase that tracking is disabled
      if (_parentId != null && _childId != null) {
        await _locationDataSource.enableLocationTracking(
          parentId: _parentId!,
          childId: _childId!,
          enabled: false,
        );
      }

      print('Location tracking stopped successfully');
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  /// Handle location updates
  Future<void> _onLocationUpdate(Position position) async {
    if (!_isTracking || _parentId == null || _childId == null) {
      return;
    }

    try {
      // Get address from coordinates
      String address = 'Location not available';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
          address = address.replaceAll(RegExp(r',\s*,'), ',').trim();
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Create location model
      final location = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        isTrackingEnabled: true,
        status: 'online',
      );

      // Get battery level
      int batteryLevel = 0;
      try {
        batteryLevel = await _battery.batteryLevel;
        print('🔋 [ChildLocation] Battery level retrieved: $batteryLevel%');
      } catch (e) {
        print('⚠️ [ChildLocation] Error getting battery level: $e');
      }
      
      // Update location in Firebase (also includes battery)
      print('📍 [ChildLocation] Updating location to Firebase...');
      print('📍 [ChildLocation] ParentId: $_parentId, ChildId: $_childId');
      print('📍 [ChildLocation] Location: ${position.latitude}, ${position.longitude}');
      print('📍 [ChildLocation] Address: ${location.address}');
      
      await _locationDataSource.updateChildLocation(
        parentId: _parentId!,
        childId: _childId!,
        location: location,
      );
      
      print('✅ [ChildLocation] Location updated in Firebase');
      
      // Update battery level in child document
      try {
        await _firestore
            .collection('parents')
            .doc(_parentId!)
            .collection('children')
            .doc(_childId!)
            .update({
          'batteryLevel': batteryLevel,
          'batteryUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ [ChildLocation] Battery level updated: $batteryLevel%');
      } catch (e) {
        print('❌ [ChildLocation] Error updating battery level: $e');
      }

      print('✅ [ChildLocation] Location updated: ${position.latitude}, ${position.longitude}');
      print('🔋 [ChildLocation] Battery level: $batteryLevel%');
    } catch (e) {
      print('❌ [ChildLocation] Error updating location: $e');
      print('   Stack trace: ${e.toString()}');
    }
  }

  /// Check if location tracking is active
  bool get isTrackingActive => _isTracking;

  /// Start battery tracking
  Future<void> _startBatteryTracking() async {
    try {
      // Update battery immediately
      await _updateBatteryLevel();
      
      // Update battery every 30 seconds
      _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _updateBatteryLevel();
      });
      
      // Also listen to battery state changes
      _batteryStream = _battery.onBatteryStateChanged.listen((BatteryState state) {
        _updateBatteryLevel();
      });
    } catch (e) {
      print('Error starting battery tracking: $e');
    }
  }

  /// Update battery level in Firebase
  Future<void> _updateBatteryLevel() async {
    if (_parentId == null || _childId == null) return;
    
    try {
      final batteryLevel = await _battery.batteryLevel;
      await _firestore
          .collection('parents')
          .doc(_parentId!)
          .collection('children')
          .doc(_childId!)
          .update({
        'batteryLevel': batteryLevel,
        'batteryUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('🔋 [ChildLocation] Battery level updated: $batteryLevel%');
    } catch (e) {
      print('Error updating battery level: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    print('Disposing ChildLocationService...');
    _isTracking = false;
    _positionStream?.cancel();
    _positionStream = null;
    _batteryStream?.cancel();
    _batteryStream = null;
    _locationTimer?.cancel();
    _locationTimer = null;
    _batteryTimer?.cancel();
    _batteryTimer = null;
    
    print('ChildLocationService disposed');
  }
}
