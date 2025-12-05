import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../url_tracking/data/models/visited_url_firebase.dart';
import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../app_limits/data/models/installed_app_firebase.dart';
import '../../../app_limits/data/services/app_limits_firebase_service.dart';
import '../../data/services/parent_dashboard_firebase_service.dart';
import '../bloc/parent_dashboard_bloc.dart';
import '../bloc/parent_dashboard_event.dart';
import '../bloc/parent_dashboard_state.dart';
import '../widgets/url_list_item.dart';
import '../widgets/app_usage_card.dart';
import '../widgets/daily_screen_time_chart.dart';
import '../widgets/usage_summary_card.dart';
import 'url_history_screen.dart';
import 'app_usage_history_screen.dart';
import 'installed_apps_tab_content.dart' show InstalledAppsTabContent;

class ParentDashboardScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const ParentDashboardScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AppLimitsFirebaseService _appLimitsService = AppLimitsFirebaseService();
  final ParentDashboardFirebaseService _parentDashboardService = ParentDashboardFirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load data when screen initializes
    context.read<ParentDashboardBloc>().add(LoadDashboardData(
      childId: widget.childId,
      parentId: widget.parentId,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.childName}\'s Activity'),
        backgroundColor: Colors.purple[100],
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ParentDashboardBloc>().add(LoadDashboardData(
                childId: widget.childId,
                parentId: widget.parentId,
              ));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'vpn',
                child: Row(
                  children: [
                    Icon(Icons.vpn_lock),
                    SizedBox(width: 8),
                    Text('VPN Control'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.calendar_view_week), text: 'Week'),
            Tab(icon: Icon(Icons.apps), text: 'All Apps'),
            Tab(icon: Icon(Icons.phone_android), text: 'Installed'),
          ],
        ),
      ),
      body: BlocConsumer<ParentDashboardBloc, ParentDashboardState>(
        listener: (context, state) {
          if (state is ParentDashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ParentDashboardLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading ${widget.childName}\'s data...'),
                ],
              ),
            );
          }

          if (state is ParentDashboardLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(state),
                _buildWeekTab(state),
                _buildAllAppsTab(state),
                _buildInstalledAppsTab(state),
              ],
            );
          }

          return Center(
            child: Text('No data available'),
          );
        },
      ),
    );
  }

  Widget _buildTodayTab(ParentDashboardLoaded state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary
          UsageSummaryCard(
            title: "Today's Summary",
            screenTime: state.todaySummary['screenTime'] ?? '0m',
            unlocks: state.todaySummary['totalLaunches'] ?? 0,
            totalApps: state.todaySummary['totalApps'] ?? 0,
          ),
          
          SizedBox(height: 20),
          
          // URL Tracking Card
          _buildUrlTrackingCard(state),
          
          SizedBox(height: 20),
          
          // App Usage Card
          _buildAppUsageCard(state),
          
          SizedBox(height: 20),
          
          // Most Used Apps Today
          Text(
            'Most Used Apps Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          ...state.mostUsedApps.take(5).map((app) => AppUsageCard(
            app: app,
            onTap: () => _showAppDetails(app),
          )),
          
          SizedBox(height: 20),
          
          // Newly Installed Apps
          if (state.installedApps.any((app) => app.isNewInstallation)) ...[
            Text(
              '🆕 Newly Installed Apps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...state.installedApps
                .where((app) => app.isNewInstallation)
                .take(5)
                .map((app) => _buildInstalledAppCard(app))
                ,
            SizedBox(height: 20),
          ],
          
          // Recent URLs
          Text(
            'Recent URLs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          ...state.recentUrls.take(5).map((url) => UrlListItem(
            url: url,
            onTap: () => _launchUrl(url.url),
            onBlockToggle: (isBlocked) => _toggleUrlBlock(url, isBlocked),
          )),
        ],
      ),
    );
  }

  Widget _buildWeekTab(ParentDashboardLoaded state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This Week's Summary
          UsageSummaryCard(
            title: "This Week's Summary",
            screenTime: state.weekSummary['screenTime'] ?? '0h',
            unlocks: state.weekSummary['totalLaunches'] ?? 0,
            totalApps: state.weekSummary['totalApps'] ?? 0,
          ),
          
          SizedBox(height: 20),
          
          // Daily Screen Time Chart
          Text(
            'Daily Screen Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          DailyScreenTimeChart(
            dailyData: state.dailyScreenTime,
          ),
          
          SizedBox(height: 20),
          
          // Most Used Apps This Week
          Text(
            'Most Used Apps This Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          ...state.mostUsedApps.take(10).map((app) => AppUsageCard(
            app: app,
            onTap: () => _showAppDetails(app),
          )),
        ],
      ),
    );
  }

  Widget _buildAllAppsTab(ParentDashboardLoaded state) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showGlobalScreenTimeLimitDialog(),
                icon: Icon(Icons.timer),
                label: Text('Screen limit'),
              ),
            ],
          ),
        ),
        
        // Apps List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.allApps.length,
            itemBuilder: (context, index) {
              final app = state.allApps[index];
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

  void _handleMenuAction(String value) {
    switch (value) {
      case 'vpn':
        _showVpnControlDialog();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  void _showVpnControlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.vpn_lock, color: Colors.blue),
            SizedBox(width: 8),
            Text('VPN Blocking Control'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System-level URL blocking using VPN service.'),
            SizedBox(height: 16),
            Text('This will block URLs at the device level - they won\'t be accessible in any browser.'),
            SizedBox(height: 16),
            Text('Currently blocked domains: 0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement VPN start
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('VPN blocking started')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Start VPN'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement VPN stop
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('VPN blocking stopped')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Stop VPN'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Content Filtering'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _setAppLimit(app),
            child: Text('Set Limit'),
          ),
        ],
      ),
    );
  }

  void _setAppLimit(AppUsageFirebase app) {
    Navigator.of(context).pop();
    _showAppLimitsDialogForAppUsage(app);
  }

  void _showAppLimitsDialogForAppUsage(AppUsageFirebase app) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Daily Limit for ${app.appName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Daily Limit',
                suffixText: 'Minutes',
                hintText: 'e.g., 60',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text(
              'Set a daily time limit for this app. The app will be blocked once the limit is reached.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                try {
                  await _appLimitsService.setAppLimit(
                    childId: widget.childId,
                    parentId: widget.parentId,
                    packageName: app.packageName,
                    appName: app.appName,
                    dailyLimitMinutes: minutes,
                  );
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('App limit set: ${app.appName} - $minutes minutes/day'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh dashboard data
                  context.read<ParentDashboardBloc>().add(LoadDashboardData(
                    childId: widget.childId,
                    parentId: widget.parentId,
                  ));
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error setting app limit: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid number of minutes'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleUrlBlock(VisitedUrlFirebase url, bool isBlocked) {
    context.read<ParentDashboardBloc>().add(UpdateUrlBlockStatus(
      childId: widget.childId,
      parentId: widget.parentId,
      urlId: url.id,
      isBlocked: isBlocked,
    ));
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch URL: $url'),
          backgroundColor: Colors.red,
        ),
      );
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

  // URL Tracking Card
  Widget _buildUrlTrackingCard(ParentDashboardLoaded state) {
    final totalUrls = state.recentUrls.length;
    final safeUrls = state.recentUrls.where((url) => !url.isBlocked).length;
    final blockedUrls = state.recentUrls.where((url) => url.isBlocked).length;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.language, color: Colors.blue[700]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URL Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Monitor browsing activity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () => _showUrlHistory(state),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total URLs',
                    totalUrls.toString(),
                    Colors.blue,
                    Icons.link,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Safe URLs',
                    safeUrls.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Blocked URLs',
                    blockedUrls.toString(),
                    Colors.red,
                    Icons.block,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // App Usage Card
  Widget _buildAppUsageCard(ParentDashboardLoaded state) {
    final totalApps = state.allApps.length;
    final totalUsage = state.todaySummary['totalUsageMinutes'] ?? 0;
    final totalLaunches = state.todaySummary['totalLaunches'] ?? 0;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple[100],
                  child: Icon(Icons.phone_android, color: Colors.purple[700]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Usage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Monitor app activity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  onPressed: () => _showAppUsageHistory(state),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Apps',
                    totalApps.toString(),
                    Colors.purple,
                    Icons.apps,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Screen Time',
                    _formatDuration(totalUsage),
                    Colors.orange,
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Launches',
                    totalLaunches.toString(),
                    Colors.teal,
                    Icons.launch,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Stat Item Widget
  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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

  // Show URL History
  void _showUrlHistory(ParentDashboardLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrlHistoryScreen(
          urls: state.recentUrls,
          childId: widget.childId,
          parentId: widget.parentId,
        ),
      ),
    );
  }

  // Show App Usage History
  void _showAppUsageHistory(ParentDashboardLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppUsageHistoryScreen(
          apps: state.allApps,
          childId: widget.childId,
          parentId: widget.parentId,
        ),
      ),
    );
  }

  // Build Installed Apps Tab
  Widget _buildInstalledAppsTab(ParentDashboardLoaded state) {
    // Use StreamBuilder for real-time updates
    return StreamBuilder<List<InstalledAppFirebase>>(
      stream: _parentDashboardService.getInstalledAppsStream(
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
        print('📱 [ParentDashboardScreen] Installed apps count: ${installedApps.length}');
        if (installedApps.isEmpty) {
          print('⚠️ [ParentDashboardScreen] No installed apps found in Firebase');
          print('   Child ID: ${widget.childId}');
          print('   Parent ID: ${widget.parentId}');
        }
        
        final newApps = installedApps.where((app) => app.isNewInstallation).toList();
        final userApps = installedApps.where((app) => !app.isSystemApp).toList();
        final systemApps = installedApps.where((app) => app.isSystemApp).toList();
        
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

  // Build Installed App Card
  Widget _buildInstalledAppCard(InstalledAppFirebase app) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: app.isNewInstallation ? Colors.green[100] : Colors.blue[100],
          child: Icon(
            app.isSystemApp ? Icons.settings : Icons.apps,
            color: app.isNewInstallation ? Colors.green : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                app.appName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (app.isNewInstallation)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Package: ${app.packageName}'),
            if (app.versionName != null)
              Text('Version: ${app.versionName}'),
            Text(
              'Installed: ${_formatDateTime(app.installTime)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.timer),
          onPressed: () => _setAppLimitForInstalledApp(app),
          tooltip: 'Set App Limit',
        ),
      ),
    );
  }

  void _setAppLimitForInstalledApp(InstalledAppFirebase app) {
    // Show app limit dialog for installed app
    _showAppLimitsDialogForApp(app);
  }

  void _showGlobalScreenTimeLimitDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Global Screen Time Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Daily Limit',
                suffixText: 'Minutes',
                hintText: 'e.g., 120 (2 hours)',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text(
              'Set a global daily screen time limit for all apps. The device will be locked when the limit is reached.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                try {
                  await _appLimitsService.setGlobalScreenTimeLimit(
                    childId: widget.childId,
                    parentId: widget.parentId,
                    dailyLimitMinutes: minutes,
                  );
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Global screen time limit set: $minutes minutes/day'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh dashboard data
                  context.read<ParentDashboardBloc>().add(LoadDashboardData(
                    childId: widget.childId,
                    parentId: widget.parentId,
                  ));
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error setting global limit: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid number of minutes'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAppLimitsDialogForApp(InstalledAppFirebase app) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Daily Limit for ${app.appName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Daily Limit',
                suffixText: 'Minutes',
                hintText: 'e.g., 60',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text(
              'Set a daily time limit for this app. The app will be blocked once the limit is reached.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                try {
                  await _appLimitsService.setAppLimit(
                    childId: widget.childId,
                    parentId: widget.parentId,
                    packageName: app.packageName,
                    appName: app.appName,
                    dailyLimitMinutes: minutes,
                  );
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('App limit set: ${app.appName} - $minutes minutes/day'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh dashboard data
                  context.read<ParentDashboardBloc>().add(LoadDashboardData(
                    childId: widget.childId,
                    parentId: widget.parentId,
                  ));
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error setting app limit: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid number of minutes'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
