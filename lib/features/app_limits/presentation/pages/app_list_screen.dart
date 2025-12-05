import 'package:flutter/material.dart';
import '../../data/models/installed_app.dart';
import '../../data/models/app_usage_stats.dart';
import '../../data/datasources/app_list_service.dart';
import '../../data/datasources/usage_stats_service.dart';

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  final AppListService _appListService = AppListService();
  final UsageStatsService _usageStatsService = UsageStatsService();
  List<InstalledApp> _apps = [];
  final Map<String, AppUsageStats> _appUsageMap = {};
  bool _isLoading = true;
  bool _showUserAppsOnly = true;
  bool _showUsageStats = true;
  String _searchQuery = '';
  int _usageStatsDays = 1;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = _showUserAppsOnly 
          ? await _appListService.getUserApps()
          : await _appListService.getInstalledApps();
      
      // Load usage statistics if enabled
      if (_showUsageStats) {
        await _loadUsageStats();
      }
      
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading apps: $e');
    }
  }

  Future<void> _loadUsageStats() async {
    try {
      final hasPermission = await _usageStatsService.hasUsageStatsPermission();
      if (!hasPermission) {
        _showPermissionDialog();
        return;
      }

      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: _usageStatsDays));
      final usageStats = await _usageStatsService.getAppUsageStats(
        startTime: startTime,
        endTime: now,
      );
      
      final appUsageMap = <String, AppUsageStats>{};
      for (final stat in usageStats) {
        appUsageMap[stat.packageName] = stat;
      }
      
      setState(() {
        _appUsageMap.clear();
        _appUsageMap.addAll(appUsageMap);
      });
    } catch (e) {
      print('Error loading usage stats: $e');
      _showErrorSnackBar('Error loading usage stats: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To show app usage statistics, you need to grant "Usage Access" permission.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Steps to enable:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Tap "Open Settings" below'),
            Text('2. Find "Content Control" in the list'),
            Text('3. Toggle "Allow usage access" ON'),
            Text('4. Return to this app'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Without this permission, usage time will show as 0 minutes.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _usageStatsService.requestUsageStatsPermission();
              // Wait a bit for user to grant permission
              await Future.delayed(Duration(seconds: 2));
              await _loadUsageStats();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  List<InstalledApp> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return _apps;
    }
    
    return _apps.where((app) {
      return app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Installed Apps (${_filteredApps.length})'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showUserAppsOnly ? Icons.person : Icons.all_inclusive),
            onPressed: () {
              setState(() {
                _showUserAppsOnly = !_showUserAppsOnly;
              });
              _loadApps();
            },
            tooltip: _showUserAppsOnly ? 'Show All Apps' : 'Show User Apps Only',
          ),
          IconButton(
            icon: Icon(_showUsageStats ? Icons.analytics : Icons.analytics_outlined),
            onPressed: () {
              setState(() {
                _showUsageStats = !_showUsageStats;
              });
              if (_showUsageStats) {
                _loadUsageStats();
              }
            },
            tooltip: _showUsageStats ? 'Hide Usage Stats' : 'Show Usage Stats',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _loadApps();
                  break;
                case 'usage_1':
                  setState(() {
                    _usageStatsDays = 1;
                  });
                  if (_showUsageStats) _loadUsageStats();
                  break;
                case 'usage_7':
                  setState(() {
                    _usageStatsDays = 7;
                  });
                  if (_showUsageStats) _loadUsageStats();
                  break;
                case 'usage_30':
                  setState(() {
                    _usageStatsDays = 30;
                  });
                  if (_showUsageStats) _loadUsageStats();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'usage_1',
                child: Row(
                  children: [
                    Icon(Icons.today),
                    SizedBox(width: 8),
                    Text('Usage: Last 1 Day'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'usage_7',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week),
                    SizedBox(width: 8),
                    Text('Usage: Last 7 Days'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'usage_30',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month),
                    SizedBox(width: 8),
                    Text('Usage: Last 30 Days'),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Usage stats summary
          if (_showUsageStats && _appUsageMap.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Text(
                    'Usage Stats: Last $_usageStatsDays day${_usageStatsDays > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          
          // Apps list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apps,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No apps found',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Try a different search term',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final usageStats = _appUsageMap[app.packageName];
                          return _buildAppCard(app, usageStats);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(InstalledApp app, AppUsageStats? usageStats) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          app.appName,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.packageName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (_showUsageStats && usageStats != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Usage Time: ${usageStats.formattedUsageTime}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.launch, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Launches: ${usageStats.launchCount}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (usageStats.lastTimeUsed.millisecondsSinceEpoch > 0) ...[
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Last used: ${usageStats.formattedLastUsed}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showUsageStats && usageStats != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: usageStats.foregroundTime.inMinutes > 0 
                      ? Colors.green[100] 
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  usageStats.foregroundTime.inMinutes > 0 
                      ? '${usageStats.foregroundTime.inMinutes}m' 
                      : '0m',
                  style: TextStyle(
                    color: usageStats.foregroundTime.inMinutes > 0 
                        ? Colors.green[800] 
                        : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.launch, color: Colors.blue),
              onPressed: () => _launchApp(app.packageName),
              tooltip: 'Launch App',
            ),
          ],
        ),
        onTap: () => _showAppDetails(app, usageStats),
      ),
    );
  }

  Future<void> _launchApp(String packageName) async {
    try {
      final success = await _appListService.launchApp(packageName);
      if (success) {
        _showSuccessSnackBar('App launched successfully');
      } else {
        _showErrorSnackBar('Failed to launch app');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching app: $e');
    }
  }

  void _showAppDetails(InstalledApp app, AppUsageStats? usageStats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                app.appName,
                style: TextStyle(fontSize: 18),
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
              _buildDetailRow('Version', app.versionName ?? 'Unknown'),
              _buildDetailRow('Version Code', app.versionCode?.toString() ?? 'Unknown'),
              _buildDetailRow('Install Date', _formatDate(app.installTime)),
              _buildDetailRow('Last Update', _formatDate(app.lastUpdateTime)),
              _buildDetailRow('Type', app.isSystemApp ? 'System App' : 'User App'),
              
              if (_showUsageStats && usageStats != null) ...[
                Divider(),
                Text(
                  'Usage Statistics (Last $_usageStatsDays day${_usageStatsDays > 1 ? 's' : ''})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow('Usage Time', usageStats.formattedUsageTime),
                _buildDetailRow('Launch Count', usageStats.launchCount.toString()),
                _buildDetailRow('Last Used', usageStats.formattedLastUsed),
                if (usageStats.lastTimeUsed.millisecondsSinceEpoch > 0)
                  _buildDetailRow('Last Used Date', _formatDate(usageStats.lastTimeUsed)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchApp(app.packageName);
            },
            child: Text('Launch App'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
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
}