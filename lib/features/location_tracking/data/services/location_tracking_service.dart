import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../datasources/location_remote_datasource.dart';

class LocationTrackingService {
  final LocationRemoteDataSource _locationDataSource;
  final FirebaseFirestore _firestore;
  
  StreamSubscription<Position>? _positionStream;
  Timer? _locationTimer;
  String? _currentParentId;
  String? _currentChildId;
  bool _isTracking = false;

  LocationTrackingService({
    required LocationRemoteDataSource locationDataSource,
    FirebaseFirestore? firestore,
  }) : _locationDataSource = locationDataSource,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Start location tracking for a child
  Future<void> startLocationTracking({
    required String parentId,
    required String childId,
  }) async {
    try {
      _currentParentId = parentId;
      _currentChildId = childId;
      _isTracking = true;

      // Request location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Enable location services
      await _locationDataSource.enableLocationTracking(
        parentId: parentId,
        childId: childId,
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

      print('Location tracking started for child: $childId');
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    try {
      _isTracking = false;
      await _positionStream?.cancel();
      _positionStream = null;
      
      if (_currentParentId != null && _currentChildId != null) {
        await _locationDataSource.enableLocationTracking(
          parentId: _currentParentId!,
          childId: _currentChildId!,
          enabled: false,
        );
      }

      print('Location tracking stopped');
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  /// Handle location updates
  Future<void> _onLocationUpdate(Position position) async {
    if (!_isTracking || _currentParentId == null || _currentChildId == null) {
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

      // Update location in Firebase
      await _locationDataSource.updateChildLocation(
        parentId: _currentParentId!,
        childId: _currentChildId!,
        location: location,
      );

      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Get current location of a child
  Future<LocationModel?> getChildCurrentLocation({
    required String parentId,
    required String childId,
  }) async {
    try {
      return await _locationDataSource.getChildLocation(
        parentId: parentId,
        childId: childId,
      );
    } catch (e) {
      print('Error getting child location: $e');
      return null;
    }
  }

  /// Get location history for a child
  Future<List<LocationModel>> getLocationHistory({
    required String parentId,
    required String childId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _locationDataSource.getLocationHistory(
        parentId: parentId,
        childId: childId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error getting location history: $e');
      return [];
    }
  }

  /// Stream child location updates
  Stream<LocationModel> streamChildLocation({
    required String parentId,
    required String childId,
  }) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('location')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return LocationModel.fromMap(snapshot.data()!);
      }
      throw Exception('Location not found');
    });
  }

  /// Check if location tracking is active
  bool get isTrackingActive => _isTracking;

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
    _locationTimer?.cancel();
  }
}
