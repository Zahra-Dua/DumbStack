import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'recommendation_service.dart';

/// Periodic Recommendation Generation Service
/// 
/// Automatically generates AI recommendations for all children
/// at regular intervals (default: every 6 hours)
class PeriodicRecommendationService {
  final RecommendationService _recommendationService = RecommendationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _recommendationTimer;
  bool _isRunning = false;
  Duration _interval = const Duration(hours: 6); // Default: 6 hours

  /// Start periodic recommendation generation
  void startPeriodicGeneration({Duration? interval}) {
    if (_isRunning) {
      print('⚠️ [PeriodicRecommendationService] Already running');
      return;
    }

    if (interval != null) {
      _interval = interval;
    }

    print('🔄 [PeriodicRecommendationService] Starting periodic recommendation generation');
    print('   Interval: ${_interval.inHours} hours');

    _recommendationService.initialize();
    _isRunning = true;

    // Generate immediately on start
    _generateRecommendations();

    // Then generate periodically
    _recommendationTimer = Timer.periodic(_interval, (_) {
      _generateRecommendations();
    });
  }

  /// Stop periodic recommendation generation
  void stopPeriodicGeneration() {
    _recommendationTimer?.cancel();
    _recommendationTimer = null;
    _isRunning = false;
    print('⏹️ [PeriodicRecommendationService] Stopped periodic recommendation generation');
  }

  /// Generate recommendations for current parent
  Future<void> _generateRecommendations() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('⚠️ [PeriodicRecommendationService] No user logged in');
        return;
      }

      final parentId = currentUser.uid;
      print('🤖 [PeriodicRecommendationService] Generating recommendations for parent: $parentId');
      
      await _recommendationService.generateRecommendationsForAllChildren(parentId);
      
      print('✅ [PeriodicRecommendationService] Recommendations generated successfully');
    } catch (e) {
      print('❌ [PeriodicRecommendationService] Error generating recommendations: $e');
    }
  }

  /// Check if service is running
  bool get isRunning => _isRunning;

  /// Dispose resources
  void dispose() {
    stopPeriodicGeneration();
  }
}

