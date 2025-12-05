import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/visited_url.dart';

class FirebaseSyncService {
  final bool enabled;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

   FirebaseSyncService({required this.enabled});

  Future<void> syncUrlToFirebase(VisitedUrl url, String childId, String parentId) async {
    if (!enabled) return;

    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .doc(url.id)
          .set(url.toJson());

      print('🔥 Firebase: Synced URL: ${url.url}');
    } catch (e) {
      print('❌ Firebase: Error syncing URL: $e');
    }
  }

  Future<List<VisitedUrl>> getUrlsFromFirebase(String childId, String parentId) async {
    if (!enabled) return [];

    try {
      final snapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .orderBy('visitedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VisitedUrl.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Firebase: Error getting URLs: $e');
      return [];
    }
  }
}
