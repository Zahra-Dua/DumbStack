import '../models/visited_url.dart';

/// FirebaseSyncService is a safe stub that no-ops unless explicitly enabled.
/// This lets the app compile without firebase_* dependencies while keeping
/// the call sites ready for future integration.
class FirebaseSyncService {
  final bool enabled;

  const FirebaseSyncService({this.enabled = false});

  Future<void> addVisitedUrl(VisitedUrl url) async {
    if (!enabled) {
      // No-op. Enable by constructing with enabled: true and wiring real impl.
      return;
    }
    // Real implementation should push to Firebase here.
  }
}


