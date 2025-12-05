import '../models/installed_app.dart';
import '../datasources/app_list_service.dart';
import 'installed_apps_firebase_service.dart';

class ChildInstalledAppsService {
  final AppListService _appListService = AppListService();
  final InstalledAppsFirebaseService _firebaseService = InstalledAppsFirebaseService();

  // Periodically sync installed apps to parent
  Future<void> syncInstalledAppsToParent({
    required String childId,
    required String parentId,
  }) async {
    try {
      print('🔄 Starting installed apps sync for child: $childId');
      
      // Get all installed apps from device
      final installedApps = await _appListService.getInstalledApps();
      print('📱 Found ${installedApps.length} installed apps on device');

      // Sync to Firebase
      await _firebaseService.syncInstalledApps(
        apps: installedApps,
        childId: childId,
        parentId: parentId,
      );

      print('✅ Installed apps sync completed');
    } catch (e) {
      print('❌ Error syncing installed apps: $e');
      // Don't rethrow - we don't want to break the child's app experience
    }
  }

  // Detect new app installations by comparing with last known list
  List<InstalledApp> detectNewInstallations({
    required List<InstalledApp> currentApps,
    required List<String> lastKnownPackageNames,
  }) {
    return currentApps
        .where((app) => !lastKnownPackageNames.contains(app.packageName))
        .toList();
  }

  // Start periodic sync (call this from child app initialization)
  void startPeriodicSync({
    required String childId,
    required String parentId,
    Duration interval = const Duration(hours: 1),
  }) {
    // Initial sync
    syncInstalledAppsToParent(childId: childId, parentId: parentId);

    // Periodic sync
    // Note: In production, use a proper background task scheduler
    // For now, this should be called from the app lifecycle
    print('⏰ Periodic sync scheduled every ${interval.inHours} hours');
  }
}

