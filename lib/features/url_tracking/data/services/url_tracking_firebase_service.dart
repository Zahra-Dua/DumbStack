import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/visited_url_firebase.dart';
import 'safe_browsing_service.dart';

class UrlTrackingFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload URL to Firebase with Safe Browsing API integration
  Future<void> uploadUrlToFirebase({
    required String url,
    required String title,
    required String packageName,
    required String childId,
    required String parentId,
    String? browserName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final urlId = 'url_${DateTime.now().millisecondsSinceEpoch}';
      
      // Check URL safety using Safe Browsing API (with timeout to prevent blocking)
      Map<String, dynamic> safetyCheck;
      try {
        safetyCheck = await SafeBrowsingService.checkUrlSafety(url)
            .timeout(const Duration(seconds: 3), onTimeout: () {
          print('⚠️ Safe Browsing check timeout, defaulting to safe');
          return {'isSafe': true, 'threatType': null};
        });
      } catch (e) {
        print('⚠️ Safe Browsing check failed: $e, defaulting to safe');
        safetyCheck = {'isSafe': true, 'threatType': null};
      }
      
      final isSafe = safetyCheck['isSafe'] ?? true;
      final threatType = safetyCheck['threatType'] as String?;
      final riskLevel = isSafe ? 'LOW' : SafeBrowsingService.getRiskLevel(threatType ?? '');
      
      // Determine if URL is malicious or spam
      final isMalicious = !isSafe && (threatType == 'MALWARE' || threatType == 'SOCIAL_ENGINEERING' || threatType == 'POTENTIALLY_HARMFUL_APPLICATION');
      final isSpam = !isSafe && threatType == 'UNWANTED_SOFTWARE';
      final isBlocked = !isSafe; // Auto-block unsafe URLs
      
      // Add safety information to metadata
      final enhancedMetadata = {
        ...?metadata,
        'safetyCheck': safetyCheck,
        'riskLevel': riskLevel,
        'threatDescription': isSafe 
            ? 'Safe URL'
            : SafeBrowsingService.getThreatTypeDescription(threatType ?? ''),
      };
      
      final visitedUrl = VisitedUrlFirebase(
        id: urlId,
        url: url,
        title: title,
        packageName: packageName,
        visitedAt: DateTime.now(),
        browserName: browserName,
        metadata: enhancedMetadata,
        isBlocked: isBlocked,
        isMalicious: isMalicious,
        isSpam: isSpam,
        threatType: threatType,
        riskLevel: riskLevel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firebasePath = 'parents/$parentId/children/$childId/visitedUrls/$urlId';
      print('📤 Uploading to Firebase: $firebasePath');
      print('📤 Data: ${visitedUrl.toJson()}');
      
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .doc(urlId)
          .set(visitedUrl.toJson());

      print('✅ URL uploaded to Firebase successfully!');
      print('✅ Path: $firebasePath');
      print('✅ URL: $url');
      print('✅ Safe: ${safetyCheck['isSafe']}');
    } catch (e) {
      print('❌ Error uploading URL to Firebase: $e');
      print('❌ Parent ID: $parentId');
      print('❌ Child ID: $childId');
      print('❌ URL: $url');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Update URL block status in Firebase
  Future<void> updateUrlBlockStatus({
    required String childId,
    required String parentId,
    required String urlId,
    required bool isBlocked,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .doc(urlId)
          .update({
        'isBlocked': isBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ URL block status updated in Firebase: $urlId -> $isBlocked');
    } catch (e) {
      print('❌ Error updating URL block status: $e');
      rethrow;
    }
  }

  // Delete URL from Firebase
  Future<void> deleteUrlFromFirebase({
    required String childId,
    required String parentId,
    required String urlId,
  }) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('visitedUrls')
          .doc(urlId)
          .delete();

      print('✅ URL deleted from Firebase: $urlId');
    } catch (e) {
      print('❌ Error deleting URL from Firebase: $e');
      rethrow;
    }
  }

  // Get current user info
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Batch upload multiple URLs
  Future<void> batchUploadUrls({
    required List<VisitedUrlFirebase> urls,
    required String childId,
    required String parentId,
  }) async {
    if (urls.isEmpty) return;

    try {
      final batch = _firestore.batch();
      
      for (final url in urls) {
        final docRef = _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('visitedUrls')
            .doc(url.id);
        
        batch.set(docRef, url.toJson());
      }

      await batch.commit();
      print('✅ Batch uploaded ${urls.length} URLs to Firebase');
    } catch (e) {
      print('❌ Error batch uploading URLs: $e');
      rethrow;
    }
  }
}
