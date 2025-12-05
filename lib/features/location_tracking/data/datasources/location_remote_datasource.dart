import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../models/child_location_model.dart';

abstract class LocationRemoteDataSource {
  Future<void> updateChildLocation({
    required String parentId,
    required String childId,
    required LocationModel location,
  });
  
  Future<LocationModel?> getChildLocation({
    required String parentId,
    required String childId,
  });
  
  Future<void> enableLocationTracking({
    required String parentId,
    required String childId,
    required bool enabled,
  });
  
  Future<List<LocationModel>> getLocationHistory({
    required String parentId,
    required String childId,
    required DateTime startDate,
    required DateTime endDate,
  });
  
  Future<void> addLocationToHistory({
    required String parentId,
    required String childId,
    required LocationModel location,
  });

  // Additional methods required by repository
  Stream<ChildLocationModel> streamChildLocation(String childId);
  Future<ChildLocationModel?> getLastKnownLocation(String childId);
  Future<void> updateChildLocationSimple(ChildLocationModel location);
  Future<void> stopLocationTracking(String childId);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final FirebaseFirestore firestore;
  
  LocationRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> updateChildLocation({
    required String parentId,
    required String childId,
    required LocationModel location,
  }) async {
    try {
      print('📍 [LocationRemote] Updating child location...');
      print('📍 [LocationRemote] Path: parents/$parentId/children/$childId/location/current');
      print('📍 [LocationRemote] Location: ${location.latitude}, ${location.longitude}');
      
      // Update current location
      await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('location')
          .doc('current')
          .set(location.toMap(), SetOptions(merge: true));

      print('✅ [LocationRemote] Current location saved successfully');

      // Add to location history
      await addLocationToHistory(
        parentId: parentId,
        childId: childId,
        location: location,
      );
      
      print('✅ [LocationRemote] Location history updated');
    } catch (e) {
      print('❌ [LocationRemote] Failed to update child location: $e');
      throw Exception('Failed to update child location: $e');
    }
  }

  @override
  Future<LocationModel?> getChildLocation({
    required String parentId,
    required String childId,
  }) async {
    try {
      final doc = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('location')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        return LocationModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get child location: $e');
    }
  }

  @override
  Future<void> enableLocationTracking({
    required String parentId,
    required String childId,
    required bool enabled,
  }) async {
    try {
      await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('location')
          .doc('current')
          .update({
        'isTrackingEnabled': enabled,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to enable/disable location tracking: $e');
    }
  }

  @override
  Future<List<LocationModel>> getLocationHistory({
    required String parentId,
    required String childId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('location')
          .doc('history')
          .collection('locations')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) => LocationModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get location history: $e');
    }
  }

  @override
  Future<void> addLocationToHistory({
    required String parentId,
    required String childId,
    required LocationModel location,
  }) async {
    try {
      await firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('location')
          .doc('history')
          .collection('locations')
          .add(location.toMap());
    } catch (e) {
      throw Exception('Failed to add location to history: $e');
    }
  }

  // Additional methods required by repository
  @override
  Stream<ChildLocationModel> streamChildLocation(String childId) {
    // This is a simplified implementation - in reality you'd need to find the parent first
    // For now, we'll return an empty stream
    return Stream.empty();
  }

  @override
  Future<ChildLocationModel?> getLastKnownLocation(String childId) async {
    // This is a simplified implementation - in reality you'd need to find the parent first
    // For now, we'll return null
    return null;
  }

  @override
  Future<void> updateChildLocationSimple(ChildLocationModel location) async {
    // This is a simplified implementation - in reality you'd need parentId and childId
    // For now, we'll do nothing
  }

  @override
  Future<void> stopLocationTracking(String childId) async {
    // This is a simplified implementation - in reality you'd need to find the parent first
    // For now, we'll do nothing
  }
}