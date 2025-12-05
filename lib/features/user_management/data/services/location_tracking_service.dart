import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/child_model.dart';
import '../models/message_model.dart';
import '../datasources/firebase_parent_service.dart';

class LocationTrackingService {
  final FirebaseParentService _firebaseService = FirebaseParentService();
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUpdateTimer;
  
  // Location update interval (in seconds)
  static const int _backgroundUpdateInterval = 300; // Update every 5 minutes in background

  /// Start location tracking for a child
  Future<void> startLocationTracking({
    required String parentId,
    required String childId,
    bool isBackground = false,
  }) async {
    try {
      // Check location permissions
      final permission = await _checkLocationPermission();
      if (!permission) {
        throw Exception('Location permission denied');
      }

      // Stop any existing tracking
      await stopLocationTracking();

      // Start location stream
      final locationStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update when moved 10 meters
        ),
      );

      _positionStreamSubscription = locationStream.listen(
        (Position position) async {
          await _updateChildLocation(
            parentId: parentId,
            childId: childId,
            position: position,
          );
        },
        onError: (error) {
          print('Location tracking error: $error');
          _updateLocationStatus(parentId, childId, 'offline');
        },
      );

      // Set up periodic updates for background tracking
      if (isBackground) {
        _locationUpdateTimer = Timer.periodic(
          Duration(seconds: _backgroundUpdateInterval),
          (timer) async {
            await _getCurrentLocationAndUpdate(parentId, childId);
          },
        );
      }

      print('Location tracking started for child: $childId');
    } catch (e) {
      throw Exception('Failed to start location tracking: $e');
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    print('Location tracking stopped');
  }

  /// Get current location and update child
  Future<void> updateCurrentLocation({
    required String parentId,
    required String childId,
  }) async {
    try {
      await _getCurrentLocationAndUpdate(parentId, childId);
    } catch (e) {
      throw Exception('Failed to update current location: $e');
    }
  }

  /// Get location history for a child
  Future<List<Map<String, dynamic>>> getLocationHistory({
    required String parentId,
    required String childId,
    int limit = 50,
  }) async {
    try {
      final child = await _firebaseService.getChild(parentId, childId);
      if (child == null) {
        throw Exception('Child not found');
      }
      
      return child.locationHistory?.take(limit).toList() ?? [];
    } catch (e) {
      throw Exception('Failed to get location history: $e');
    }
  }

  /// Get real-time location stream
  Stream<ChildModel?> getLocationStream({
    required String parentId,
    required String childId,
  }) {
    return _firebaseService.getChildrenStream(parentId).map((children) {
      return children.firstWhere(
        (child) => child.childId == childId,
        orElse: () => throw Exception('Child not found'),
      );
    });
  }

  /// Check if location tracking is active
  bool get isTrackingActive {
    return _positionStreamSubscription != null;
  }

  /// Private method to check location permission
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Private method to get current location and update
  Future<void> _getCurrentLocationAndUpdate(
    String parentId,
    String childId,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      await _updateChildLocation(
        parentId: parentId,
        childId: childId,
        position: position,
      );
    } catch (e) {
      print('Error getting current location: $e');
      await _updateLocationStatus(parentId, childId, 'offline');
    }
  }

  /// Private method to update child location
  Future<void> _updateChildLocation({
    required String parentId,
    required String childId,
    required Position position,
  }) async {
    try {
      // Get address from coordinates
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Get current child data
      final child = await _firebaseService.getChild(parentId, childId);
      if (child == null) {
        throw Exception('Child not found');
      }

      // Update child with new location
      final updatedChild = child.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
      );

      // Save to Firebase
      await _firebaseService.updateChild(parentId, updatedChild);

      // Create location message for parent
      await _createLocationMessage(parentId, childId, updatedChild);

      print('Location updated for child $childId: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating child location: $e');
      await _updateLocationStatus(parentId, childId, 'offline');
    }
  }

  /// Private method to update location status
  Future<void> _updateLocationStatus(
    String parentId,
    String childId,
    String status,
  ) async {
    try {
      final child = await _firebaseService.getChild(parentId, childId);
      if (child != null) {
        final updatedChild = child.updateLocationStatus(status);
        await _firebaseService.updateChild(parentId, updatedChild);
      }
    } catch (e) {
      print('Error updating location status: $e');
    }
  }

  /// Private method to create location message
  Future<void> _createLocationMessage(
    String parentId,
    String childId,
    ChildModel child,
  ) async {
    try {
      if (child.hasCurrentLocation) {
        final locationMessage = MessageModel.createLocationMessage(
          messageId: 'loc_${DateTime.now().millisecondsSinceEpoch}',
          childId: childId,
          parentId: parentId,
          latitude: child.currentLatitude!,
          longitude: child.currentLongitude!,
          address: child.currentAddress,
          accuracy: child.locationAccuracy,
        );

        await _firebaseService.addMessage(parentId, childId, locationMessage);
      }
    } catch (e) {
      print('Error creating location message: $e');
    }
  }

  /// Get location statistics for a child
  Future<Map<String, dynamic>> getLocationStats({
    required String parentId,
    required String childId,
  }) async {
    try {
      final child = await _firebaseService.getChild(parentId, childId);
      if (child == null) {
        throw Exception('Child not found');
      }

      final history = child.locationHistory ?? [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(Duration(days: 7));

      // Count locations by day
      final todayLocations = history.where((loc) {
        final locTime = DateTime.parse(loc['timestamp']);
        return locTime.isAfter(today);
      }).length;

      final weekLocations = history.where((loc) {
        final locTime = DateTime.parse(loc['timestamp']);
        return locTime.isAfter(weekAgo);
      }).length;

      // Calculate average accuracy
      final accuracyValues = history
          .where((loc) => loc['accuracy'] != null)
          .map((loc) => loc['accuracy'] as double)
          .toList();
      
      final averageAccuracy = accuracyValues.isNotEmpty
          ? accuracyValues.reduce((a, b) => a + b) / accuracyValues.length
          : 0.0;

      return {
        'totalLocations': history.length,
        'todayLocations': todayLocations,
        'weekLocations': weekLocations,
        'averageAccuracy': averageAccuracy,
        'lastUpdate': child.lastLocationUpdateText,
        'isOnline': child.currentLocationStatus == 'online',
        'trackingEnabled': child.isLocationTrackingEnabled,
      };
    } catch (e) {
      throw Exception('Failed to get location stats: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }
}
