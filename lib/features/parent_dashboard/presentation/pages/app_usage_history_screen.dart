import 'package:flutter/material.dart';
import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../app_limits/data/models/installed_app_firebase.dart';
import '../widgets/app_usage_card.dart';
import '../../data/services/parent_dashboard_firebase_service.dart';
import 'installed_apps_tab_content.dart' show InstalledAppsTabContent;

class AppUsageHistoryScreen extends StatefulWidget {
  final List<AppUsageFirebase> apps;
  final String childId;
  final String parentId;

  const AppUsageHistoryScreen({
    super.key,
    required this.apps,
    required this.childId,
    required this.parentId,
  });

  @override
  State<AppUsageHistoryScreen> createState() => _AppUsageHistoryScreenState();
}

class _AppUsageHistoryScreenState extends State<AppUsageHistoryScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _sortBy = 'usage'; // usage, name, launches
  String _filterType = 'all'; // all, user, system
  final ParentDashboardFirebaseService _firebaseService = ParentDashboardFirebaseService();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Update UI when tab changes
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AppUsageFirebase> _filterAndSortApps(List<AppUsageFirebase> apps) {
    // Filter apps based on filter type (All, User Apps only, System Apps only)
    var filtered = apps.where((app) {
      // Filter by type
      if (_filterType == 'user' && app.isSystemApp) return false;
      if (_filterType == 'system' && !app.isSystemApp) return false;
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }
      
      return true;
    }).toList();

    // Sort apps based on selected sort option
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'usage':
          // Descending: Most used first (top)
          return b.usageDuration.compareTo(a.usageDuration);
        case 'name':
          // Ascending: Alphabetical order
          return a.appName.compareTo(b.appName);
        case 'launches':
          // Descending: Most launches first (top)
          return b.launchCount.compareTo(a.launchCount);
        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUsageFirebase>>(
      stream: _firebaseService.getAppUsageStream(
        childId: widget.childId,
        parentId: widget.parentId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('App Usage'),
              backgroundColor: Colors.purple[100],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading apps from Firebase...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('App Usage'),
              backgroundColor: Colors.purple[100],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading apps: ${snapshot.error}',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final allApps = snapshot.data ?? [];
        // Filter out system apps for display and totals
        final userApps = allApps.where((app) => !app.isSystemApp).toList();
        final filteredApps = _filterAndSortApps(allApps);

        // Calculate totals from USER apps only (excluding system apps like Gboard, System UI)
        // This gives us total screen time like Digital Wellbeing
        final totalApps = userApps.length;
        final totalUsage = userApps.fold<int>(0, (sum, app) => sum + app.usageDuration);
        final totalLaunches = userApps.fold<int>(0, (sum, app) => sum + app.launchCount);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _tabController.index == 0 
                ? 'App Usage (${filteredApps.length}${_searchQuery.isNotEmpty ? ' filtered' : ''})'
                : 'Installed Apps',
            ),
            backgroundColor: Colors.purple[100],
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _sortBy = 'usage';
                  });
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    icon: Icon(Icons.apps),
                    text: 'App Usage',
                  ),
                  Tab(
                    icon: Icon(Icons.phone_android),
                    text: 'Installed',
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAppUsageTab(allApps, userApps, filteredApps, totalApps, totalUsage, totalLaunches),
              _buildInstalledAppsTab(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAppUsageTab(
    List<AppUsageFirebase> allApps,
    List<AppUsageFirebase> userApps,
    List<AppUsageFirebase> filteredApps,
    int totalApps,
    int totalUsage,
    int totalLaunches,
  ) {
    return Column(
            children: [
              // Summary Stats
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Apps',
                        totalApps.toString(),
                        Colors.purple,
                        Icons.apps,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Screen Time',
                        _formatDuration(totalUsage),
                        Colors.orange,
                        Icons.timer,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Launches',
                        totalLaunches.toString(),
                        Colors.teal,
                        Icons.launch,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search and Sort Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search apps...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    // Filter Options (All, User Apps, System Apps)
                    Row(
                      children: [
                        Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 12),
                        _buildFilterChip('All', 'all'),
                        SizedBox(width: 8),
                        _buildFilterChip('User Apps', 'user'),
                        SizedBox(width: 8),
                        _buildFilterChip('System', 'system'),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Sort Options
                    Row(
                      children: [
                        Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 12),
                        _buildSortChip('Usage Time', 'usage'),
                        SizedBox(width: 8),
                        _buildSortChip('Name', 'name'),
                        SizedBox(width: 8),
                        _buildSortChip('Launches', 'launches'),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // App List
              Expanded(
                child: filteredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_android,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No apps found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              Text(
                                'Try adjusting your search',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              )
                            else
                              Text(
                                'Child has not used any apps yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          return AppUsageCard(
                            app: app,
                            onTap: () => _showAppDetails(app),
                            showFullDetails: true,
                          );
                        },
                      ),
              ),
            ],
    );
  }
  
  Widget _buildInstalledAppsTab() {
    return StreamBuilder<List<InstalledAppFirebase>>(
      stream: _firebaseService.getInstalledAppsStream(
        childId: widget.childId,
        parentId: widget.parentId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading installed apps...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading installed apps: ${snapshot.error}',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final installedApps = snapshot.data ?? [];
        
        // Debug: Print installed apps count
        print('📱 [AppUsageHistoryScreen] Installed apps count: ${installedApps.length}');
        if (installedApps.isEmpty) {
          print('⚠️ [AppUsageHistoryScreen] No installed apps found in Firebase');
          print('   Child ID: ${widget.childId}');
          print('   Parent ID: ${widget.parentId}');
        }
        
        final newApps = installedApps.where((app) => app.isNewInstallation).toList();
        final userApps = installedApps.where((app) => !app.isSystemApp).toList();
        final systemApps = installedApps.where((app) => app.isSystemApp).toList();
        
        // If no apps found, show helpful message
        if (installedApps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_android,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No installed apps found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Make sure child device has synced installed apps',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Refresh by rebuilding
                        setState(() {});
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100],
                        foregroundColor: Colors.purple[900],
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                          SizedBox(height: 8),
                          Text(
                            'To sync installed apps:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1. Open child device app\n2. Restart the app\n3. Wait 10-15 seconds\n4. Come back here and refresh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
              ),
            ],
          ),
          );
        }
        
        return InstalledAppsTabContent(
          allApps: installedApps,
          newApps: newApps,
          userApps: userApps,
          systemApps: systemApps,
          childId: widget.childId,
          parentId: widget.parentId,
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
      selectedColor: Colors.purple[100],
      checkmarkColor: Colors.purple[700],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  void _showAppDetails(AppUsageFirebase app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Package: ${app.packageName}'),
            SizedBox(height: 8),
            Text('Usage Time: ${_formatDuration(app.usageDuration)}'),
            Text('Launches: ${app.launchCount}'),
            Text('Last Used: ${_formatDateTime(app.lastUsed)}'),
            if (app.riskScore != null)
              Text('Risk Score: ${app.riskScore!.toStringAsFixed(2)}'),
            if (app.isSystemApp)
              Text('System App: Yes', style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _setAppLimit(app);
            },
            child: Text('Set Limit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _toggleAppBlock(app);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: app.isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(app.isBlocked ? 'Unblock App' : 'Block App'),
          ),
        ],
      ),
    );
  }

  void _setAppLimit(AppUsageFirebase app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Daily Limit for ${app.appName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Daily Limit (minutes)',
                hintText: 'Enter minutes',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('App limit set successfully')),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleAppBlock(AppUsageFirebase app) async {
    final isBlocked = !app.isBlocked;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBlocked ? 'Block App' : 'Unblock App'),
        content: Text(
          isBlocked
              ? 'Are you sure you want to block ${app.appName}? The child will not be able to use this app.'
              : 'Are you sure you want to unblock ${app.appName}? The child will be able to use this app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.red : Colors.green,
            ),
            child: Text(isBlocked ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.updateAppBlockStatus(
          childId: widget.childId,
          parentId: widget.parentId,
          packageName: app.packageName,
          isBlocked: isBlocked,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBlocked
                    ? '${app.appName} has been blocked'
                    : '${app.appName} has been unblocked',
              ),
              backgroundColor: isBlocked ? Colors.red : Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
