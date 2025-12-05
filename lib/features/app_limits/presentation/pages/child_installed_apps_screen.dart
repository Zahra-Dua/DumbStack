import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/datasources/app_list_service.dart';
import '../../data/models/installed_app.dart';
import '../../data/services/installed_apps_firebase_service.dart';

/// Child Installed Apps Screen
/// 
/// Shows all installed apps on child's device
/// Fetches apps directly from device using AppListService
class ChildInstalledAppsScreen extends StatefulWidget {
  const ChildInstalledAppsScreen({super.key});

  @override
  State<ChildInstalledAppsScreen> createState() => _ChildInstalledAppsScreenState();
}

class _ChildInstalledAppsScreenState extends State<ChildInstalledAppsScreen> {
  final AppListService _appListService = AppListService();
  final InstalledAppsFirebaseService _firebaseService = InstalledAppsFirebaseService();
  List<InstalledApp> _allApps = [];
  List<InstalledApp> _filteredApps = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'user', 'system'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstalledApps().then((_) {
      // Auto-sync to Firebase after loading apps (only if apps are loaded)
      if (_allApps.isNotEmpty) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _syncToFirebase();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📱 [ChildInstalledAppsScreen] Loading installed apps...');
      final apps = await _appListService.getInstalledApps();
      
      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
      
      print('✅ [ChildInstalledAppsScreen] Loaded ${apps.length} apps');
    } catch (e) {
      print('❌ [ChildInstalledAppsScreen] Error loading apps: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading apps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterApps() {
    List<InstalledApp> appsToShow;

    // Filter by type
    switch (_filterType) {
      case 'user':
        appsToShow = _allApps.where((app) => !app.isSystemApp).toList();
        break;
      case 'system':
        appsToShow = _allApps.where((app) => app.isSystemApp).toList();
        break;
      default:
        appsToShow = _allApps;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      appsToShow = appsToShow.where((app) {
        return app.appName.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredApps = appsToShow;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        title: const Text('Installed Apps'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _isSyncing ? null : _syncToFirebase,
            tooltip: 'Sync to Firebase',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstalledApps,
            tooltip: 'Refresh Apps',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: mq.h(0.02)),
                  const Text('Loading installed apps...'),
                ],
              ),
            )
          : Column(
              children: [
                // Summary Card
                Container(
                  padding: EdgeInsets.all(mq.w(0.04)),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(mq.w(0.04)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Apps',
                              _allApps.length.toString(),
                              Colors.blue,
                              Icons.apps,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'User Apps',
                              _allApps.where((app) => !app.isSystemApp).length.toString(),
                              Colors.green,
                              Icons.person,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'System Apps',
                              _allApps.where((app) => app.isSystemApp).length.toString(),
                              Colors.grey,
                              Icons.settings,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search and Filter Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: mq.w(0.04),
                    vertical: mq.h(0.01),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search apps...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                      _filterApps();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterApps();
                          },
                        ),
                      ),
                      SizedBox(width: mq.w(0.02)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filter Apps',
                        onSelected: (value) {
                          setState(() {
                            _filterType = value;
                          });
                          _filterApps();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'all',
                            child: Row(
                              children: [
                                const Icon(Icons.apps, size: 20),
                                const SizedBox(width: 8),
                                const Text('All Apps'),
                                if (_filterType == 'all')
                                  const Spacer(),
                                if (_filterType == 'all')
                                  const Icon(Icons.check, size: 16, color: Colors.blue),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'user',
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 20),
                                const SizedBox(width: 8),
                                const Text('User Apps'),
                                if (_filterType == 'user')
                                  const Spacer(),
                                if (_filterType == 'user')
                                  const Icon(Icons.check, size: 16, color: Colors.blue),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'system',
                            child: Row(
                              children: [
                                const Icon(Icons.settings, size: 20),
                                const SizedBox(width: 8),
                                const Text('System Apps'),
                                if (_filterType == 'system')
                                  const Spacer(),
                                if (_filterType == 'system')
                                  const Icon(Icons.check, size: 16, color: Colors.blue),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filter Chip
                if (_filterType != 'all')
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: mq.w(0.04)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(
                          _filterType == 'user'
                              ? 'User Apps Only'
                              : 'System Apps Only',
                        ),
                        avatar: Icon(
                          _filterType == 'user' ? Icons.person : Icons.settings,
                          size: 18,
                        ),
                        onDeleted: () {
                          setState(() {
                            _filterType = 'all';
                          });
                          _filterApps();
                        },
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ),

                // Apps List
                Expanded(
                  child: _filteredApps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apps,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: mq.h(0.02)),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No apps found matching "$_searchQuery"'
                                    : 'No apps found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: mq.w(0.04),
                            vertical: mq.h(0.01),
                          ),
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            return _buildAppCard(app);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAppCard(InstalledApp app) {
    final mq = MQ(context);
    return Card(
      margin: EdgeInsets.only(bottom: mq.h(0.01)),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: app.isSystemApp
              ? Colors.grey[200]
              : Colors.blue[100],
          child: Icon(
            app.isSystemApp ? Icons.settings : Icons.apps,
            color: app.isSystemApp
                ? Colors.grey[700]
                : Colors.blue[700],
            size: 24,
          ),
        ),
        title: Text(
          app.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.packageName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  app.isSystemApp ? Icons.settings : Icons.person,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  app.isSystemApp ? 'System' : 'User',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (app.versionName != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'v${app.versionName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _showAppDetails(app),
      ),
    );
  }

  void _showAppDetails(InstalledApp app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: app.isSystemApp ? Colors.grey[200] : Colors.blue[100],
              child: Icon(
                app.isSystemApp ? Icons.settings : Icons.apps,
                color: app.isSystemApp ? Colors.grey[700] : Colors.blue[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.appName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Package Name', app.packageName),
              if (app.versionName != null)
                _buildDetailRow('Version', app.versionName!),
              if (app.versionCode != null)
                _buildDetailRow('Version Code', app.versionCode.toString()),
              _buildDetailRow(
                'Type',
                app.isSystemApp ? 'System App' : 'User App',
              ),
              _buildDetailRow(
                'Install Date',
                _formatDate(app.installTime),
              ),
              _buildDetailRow(
                'Last Update',
                _formatDate(app.lastUpdateTime),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _syncToFirebase() async {
    if (_allApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No apps to sync'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Syncing apps to Firebase...'),
            ],
          ),
        ),
      );

      // Get child and parent IDs
      final prefs = await SharedPreferences.getInstance();
      final childId = prefs.getString('child_uid');
      final parentId = prefs.getString('parent_uid');

      if (childId == null || parentId == null) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Child or Parent ID not found. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSyncing = false;
        });
        return;
      }

      print('📱 [ChildInstalledAppsScreen] Syncing ${_allApps.length} apps to Firebase...');
      print('   Child ID: $childId');
      print('   Parent ID: $parentId');

      // Sync to Firebase
      await _firebaseService.syncInstalledApps(
        apps: _allApps,
        childId: childId,
        parentId: parentId,
      );

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Successfully synced ${_allApps.length} apps to Firebase!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      print('✅ [ChildInstalledAppsScreen] Apps synced successfully');
    } catch (e) {
      Navigator.pop(context); // Close loading
      print('❌ [ChildInstalledAppsScreen] Error syncing apps: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error syncing apps: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
}

