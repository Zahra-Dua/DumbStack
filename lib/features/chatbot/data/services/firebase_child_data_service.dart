import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Service for fetching complete child data
/// 
/// This service fetches all child-related data from Firebase:
/// - Child profile
/// - Usage stats
/// - Calls
/// - Messages
/// - Location
/// - Safe zones
/// - Apps
/// - Screen time
class FirebaseChildDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Find childId by searching child's name within parent's children
  /// 
  /// Searches in: parents/{parentId}/children collection
  /// Supports: firstName, lastName, full name, or combined search
  Future<String?> findChildIdByName(String name, {required String parentId}) async {
    try {
      print('🔍 [FirebaseChildDataService] Searching for child: "$name" for parent: $parentId');
      
      // Get all children for this parent
      final allChildren = await _db
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .get();

      if (allChildren.docs.isEmpty) {
        print('⚠️ [FirebaseChildDataService] No children found for parent: $parentId');
        return null;
      }

      // Normalize search name (lowercase, trim)
      final searchName = name.trim().toLowerCase();
      final isSingleWord = searchName.split(' ').length == 1;

      // Try multiple search strategies
      for (var doc in allChildren.docs) {
        final data = doc.data();
        final firstName = (data['firstName'] ?? '').toString().trim().toLowerCase();
        final lastName = (data['lastName'] ?? '').toString().trim().toLowerCase();
        final fullName = (data['name'] ?? '').toString().trim().toLowerCase();
        
        // Strategy 1: Exact match with 'name' field
        if (fullName.isNotEmpty && (fullName == searchName || fullName.contains(searchName))) {
          print('✅ [FirebaseChildDataService] Found by name field: ${doc.id}');
          return doc.id;
        }

        // Strategy 2: If single word, prioritize firstName match
        if (isSingleWord) {
          // Check firstName first (most common case)
          if (firstName.isNotEmpty && firstName == searchName) {
            print('✅ [FirebaseChildDataService] Found by firstName (exact): ${doc.id}');
            return doc.id;
          }
          
          // Then check lastName
          if (lastName.isNotEmpty && lastName == searchName) {
            print('✅ [FirebaseChildDataService] Found by lastName (exact): ${doc.id}');
            return doc.id;
          }
          
          // Then check if searchName is part of firstName
          if (firstName.isNotEmpty && firstName.contains(searchName)) {
            print('✅ [FirebaseChildDataService] Found by firstName (partial): ${doc.id}');
            return doc.id;
          }
          
          // Then check if searchName is part of lastName
          if (lastName.isNotEmpty && lastName.contains(searchName)) {
            print('✅ [FirebaseChildDataService] Found by lastName (partial): ${doc.id}');
            return doc.id;
          }
        } else {
          // Multiple words - check combined name
          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            final combinedName = '$firstName $lastName'.trim();
            if (combinedName == searchName || combinedName.contains(searchName)) {
              print('✅ [FirebaseChildDataService] Found by combined name: ${doc.id}');
              return doc.id;
            }
          }
          
          // Check firstName match
          if (firstName.isNotEmpty && (firstName == searchName || firstName.contains(searchName))) {
            print('✅ [FirebaseChildDataService] Found by firstName: ${doc.id}');
            return doc.id;
          }
          
          // Check lastName match
          if (lastName.isNotEmpty && (lastName == searchName || lastName.contains(searchName))) {
            print('✅ [FirebaseChildDataService] Found by lastName: ${doc.id}');
            return doc.id;
          }
        }

        // Strategy 3: Fallback - check if any part matches
        if (firstName.isNotEmpty && firstName.contains(searchName)) {
          print('✅ [FirebaseChildDataService] Found by firstName (fallback): ${doc.id}');
          return doc.id;
        }
        
        if (lastName.isNotEmpty && lastName.contains(searchName)) {
          print('✅ [FirebaseChildDataService] Found by lastName (fallback): ${doc.id}');
          return doc.id;
        }
      }

      print('⚠️ [FirebaseChildDataService] No child found with name: "$name"');
      return null;
    } catch (e) {
      print('❌ [FirebaseChildDataService] Error finding child: $e');
      return null;
    }
  }

  /// Get complete child data from all collections
  /// 
  /// Fetches data from (EXACT Firebase collection names):
  /// - parents/{parentId}/children/{childId} (profile)
  /// - parents/{parentId}/children/{childId}/appUsage
  /// - parents/{parentId}/children/{childId}/notifications
  /// - parents/{parentId}/children/{childId}/messages
  /// - parents/{parentId}/children/{childId}/location (NOT locations - exact Firebase name)
  /// - parents/{parentId}/children/{childId}/safezones (geofence zones)
  /// - parents/{parentId}/children/{childId}/installedApps
  /// - parents/{parentId}/children/{childId}/screenTime
  /// - parents/{parentId}/children/{childId}/flagged_messages (suspicious SMS)
  Future<Map<String, dynamic>?> getFullChildData(String childId, {required String parentId}) async {
    try {
      print('📊 [FirebaseChildDataService] Fetching full data for child: $childId');

      // Fetch all collections in parallel for better performance
      // Using EXACT Firebase collection names as they exist in database
      final results = await Future.wait([
        _db.collection('parents').doc(parentId).collection('children').doc(childId).get(),
        _getCollectionData(parentId, childId, 'appUsage'),        // ✅ Firebase: appUsage
        _getCollectionData(parentId, childId, 'notifications'),  // ✅ Firebase: notifications
        _getCollectionData(parentId, childId, 'messages'),       // ✅ Firebase: messages
        _getCollectionData(parentId, childId, 'location'),        // ✅ Firebase: location (NOT locations)
        _getCollectionData(parentId, childId, 'safezones'),       // ✅ Firebase: safezones
        _getCollectionData(parentId, childId, 'installedApps'),  // ✅ Firebase: installedApps
        _getCollectionData(parentId, childId, 'screenTime'),      // ✅ Firebase: screenTime
        _getCollectionData(parentId, childId, 'flagged_messages'), // ✅ Firebase: flagged_messages
      ]);

      final childProfile = results[0] as DocumentSnapshot;
      final appUsage = results[1] as List<Map<String, dynamic>>;
      final notifications = results[2] as List<Map<String, dynamic>>;
      final messages = results[3] as List<Map<String, dynamic>>;
      final location = results[4] as List<Map<String, dynamic>>;  // ✅ Changed: locations → location (exact Firebase name)
      final safezones = results[5] as List<Map<String, dynamic>>;
      final installedApps = results[6] as List<Map<String, dynamic>>;
      final screenTime = results[7] as List<Map<String, dynamic>>;
      final flaggedMessages = results[8] as List<Map<String, dynamic>>;

      final data = {
        "profile": childProfile.data() ?? <String, dynamic>{},
        "appUsage": appUsage,
        "notifications": notifications,
        "messages": messages,
        "location": location,  // ✅ Changed: locations → location (exact Firebase name)
        "safezones": safezones,
        "installedApps": installedApps,
        "screenTime": screenTime,
        "flaggedMessages": flaggedMessages,
      };

      print('✅ [FirebaseChildDataService] Successfully fetched child data');
      return data;
    } catch (e) {
      print('❌ [FirebaseChildDataService] Error loading full child data: $e');
      return null;
    }
  }

  /// Get data from a subcollection
  Future<List<Map<String, dynamic>>> _getCollectionData(
    String parentId,
    String childId,
    String collectionName,
  ) async {
    try {
      // Special handling for 'location' collection (has current/history structure)
      if (collectionName == 'location') {
        // Get current location
        final currentDoc = await _db
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('location')
            .doc('current')
            .get();
        
        // Get location history (if exists)
        final historySnapshot = await _db
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('location')
            .doc('history')
            .collection('locations')
            .limit(50)
            .orderBy('timestamp', descending: true)
            .get();
        
        final locationData = <Map<String, dynamic>>[];
        
        // Add current location
        if (currentDoc.exists && currentDoc.data() != null) {
          locationData.add({
            'id': 'current',
            'type': 'current',
            ...currentDoc.data()!,
          });
        }
        
        // Add history locations
        for (var doc in historySnapshot.docs) {
          locationData.add({
            'id': doc.id,
            'type': 'history',
            ...doc.data(),
          });
        }
        
        return locationData;
      }
      
      // For other collections, fetch normally
      final snapshot = await _db
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection(collectionName)
          .limit(100) // Limit to recent 100 items
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('⚠️ [FirebaseChildDataService] Error fetching $collectionName: $e');
      return [];
    }
  }

  /// Real-time stream of child data (refreshes every 10 seconds)
  Stream<Map<String, dynamic>?> watchFullChildData(String childId, {required String parentId}) async* {
    while (true) {
      final data = await getFullChildData(childId, parentId: parentId);
      yield data;
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}

