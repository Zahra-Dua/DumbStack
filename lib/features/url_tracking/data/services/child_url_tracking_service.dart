import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/visited_url_firebase.dart';
import 'url_tracking_firebase_service.dart';

class ChildUrlTrackingService {
  final UrlTrackingFirebaseService _firebaseService = UrlTrackingFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload URL when child visits a website
  Future<void> uploadVisitedUrl({
    required String url,
    required String title,
    required String packageName,
    required String childId,
    required String parentId,
    String? browserName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firebaseService.uploadUrlToFirebase(
        url: url,
        title: title,
        packageName: packageName,
        childId: childId,
        parentId: parentId,
        browserName: browserName,
        metadata: metadata,
      );
      
      print('✅ Child URL uploaded to Firebase: $url');
    } catch (e) {
      print('❌ Error uploading child URL: $e');
      // Don't rethrow - we don't want to break the child's browsing experience
    }
  }

  // Batch upload multiple URLs
  Future<void> batchUploadUrls({
    required List<Map<String, dynamic>> urls,
    required String childId,
    required String parentId,
  }) async {
    try {
      final visitedUrls = urls.map((urlData) => VisitedUrlFirebase(
        id: 'url_${DateTime.now().millisecondsSinceEpoch}_${urls.indexOf(urlData)}',
        url: urlData['url'] ?? '',
        title: urlData['title'] ?? '',
        packageName: urlData['packageName'] ?? '',
        visitedAt: urlData['visitedAt'] ?? DateTime.now(),
        browserName: urlData['browserName'],
        metadata: urlData['metadata'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();

      await _firebaseService.batchUploadUrls(
        urls: visitedUrls,
        childId: childId,
        parentId: parentId,
      );
      
      print('✅ Child batch uploaded ${urls.length} URLs to Firebase');
    } catch (e) {
      print('❌ Error batch uploading child URLs: $e');
    }
  }

  // Get current child ID (you'll need to implement this based on your auth system)
  String? getCurrentChildId() {
    return _auth.currentUser?.uid;
  }

  // Get parent ID (you'll need to implement this based on your parent-child relationship)
  Future<String?> getParentId(String childId) async {
    try {
      // This is a placeholder - implement based on your parent-child relationship structure
      // You might have a separate collection that maps childId to parentId
      final doc = await FirebaseFirestore.instance
          .collection('child_parent_mapping')
          .doc(childId)
          .get();
      
      return doc.data()?['parentId'];
    } catch (e) {
      print('❌ Error getting parent ID: $e');
      return null;
    }
  }
}
