import 'package:flutter/material.dart';
import '../../data/datasources/usage_stats_service.dart';
import '../../data/datasources/app_list_service.dart';
import '../../data/models/app_usage_stats.dart';
import '../../data/datasources/local_storage_service.dart';

class DigitalWellbeingScreen extends StatefulWidget {
  const DigitalWellbeingScreen({super.key});

  @override
  State<DigitalWellbeingScreen> createState() => _DigitalWellbeingScreenState();
}

class _DigitalWellbeingScreenState extends State<DigitalWellbeingScreen> with TickerProviderStateMixin {
  final UsageStatsService _usageStatsService = UsageStatsService();
  final AppListService _appListService = AppListService();
  final LocalStorageService _localStorage = LocalStorageService();
  
  late TabController _tabController;
  
  bool _hasPermission = false;
  bool _isLoading = true;
  
  // Today's data
  Duration _todayScreenTime = Duration.zero;
  int _todayUnlocks = 0;
  List<AppUsageStats> _todayTopApps = [];
  
  // Weekly data
  Duration _weekScreenTime = Duration.zero;
  int _weekUnlocks = 0;
  List<AppUsageStats> _weekTopApps = [];
  Map<DateTime, List<AppUsageStats>> _dailyStats = {};
  
  // All apps with usage data
  List<AppUsageStats> _allAppsUsage = [];
  Map<String, dynamic> _limits = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissionAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasPermission = await _usageStatsService.hasUsageStatsPermission();
      setState(() {
        _hasPermission = hasPermission;
      });

      if (hasPermission) {
        await _loadAllData();
      }
    } catch (e) {
      print('Error checking permission and loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllData() async {
    try {
      await _localStorage.resetDailyIfNeeded();
      _limits = await _localStorage.getAppDailyLimits();
      // Update global used & enforce if needed
      final global = await _localStorage.getGlobalDailyLimit();
      // Load today's data
      final todayScreenTime = await _usageStatsService.getTodayScreenTime();
      final todayUnlocks = await _usageStatsService.getTodayUnlockCount();
      final todayTopApps = await _usageStatsService.getTopUsedAppsToday(limit: 20);

      // Load weekly data
      final weekScreenTime = await _usageStatsService.getWeeklyScreenTime();
      final weekUnlocks = await _usageStatsService.getWeeklyUnlockCount();
      final weekTopApps = await _usageStatsService.getTopUsedAppsWeek(limit: 20);
      final dailyStats = await _usageStatsService.getDailyUsageStatsForWeek();

      // Load all apps usage
      final allAppsUsage = await _usageStatsService.getWeeklyUsageStats();

      setState(() {
        _todayScreenTime = todayScreenTime;
        _todayUnlocks = todayUnlocks;
        _todayTopApps = todayTopApps;
        _weekScreenTime = weekScreenTime;
        _weekUnlocks = weekUnlocks;
        _weekTopApps = weekTopApps;
        _dailyStats = dailyStats;
        _allAppsUsage = allAppsUsage;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _requestPermission() async {
    await _usageStatsService.requestUsageStatsPermission();
    // Wait a bit for user to grant permission
    await Future.delayed(const Duration(seconds: 2));
    await _checkPermissionAndLoadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Wellbeing'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.calendar_view_week), text: 'Week'),
            Tab(icon: Icon(Icons.apps), text: 'All Apps'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissionAndLoadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading usage data...'),
          ],
        ),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionRequired();
    }

    return SafeArea(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildWeekTab(),
          _buildAllAppsTab(),
        ],
      ),
    );
  }

  Widget _buildPermissionRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Usage Access Permission Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To track your app usage and screen time, please grant Usage Access permission.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This permission is required for:\n• App usage tracking\n• Screen time monitoring\n• Digital wellbeing features',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTodaySummary(),
          const SizedBox(height: 24),
          _buildTodayTopApps(),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Screen Time',
                    _formatDuration(_todayScreenTime),
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Unlocks',
                    '$_todayUnlocks',
                    Icons.lock_open,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTopApps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Used Apps Today',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_todayTopApps.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No usage data available for today.'),
            ),
          )
        else
          ..._todayTopApps.map((app) => _buildAppUsageCard(app, _todayScreenTime)),
      ],
    );
  }

  Widget _buildWeekTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWeekSummary(),
          const SizedBox(height: 24),
          _buildWeekChart(),
          const SizedBox(height: 24),
          _buildWeekTopApps(),
        ],
      ),
    );
  }

  Widget _buildWeekSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_view_week, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'This Week\'s Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Screen Time',
                    _formatDuration(_weekScreenTime),
                    Icons.schedule,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Unlocks',
                    '$_weekUnlocks',
                    Icons.lock_open,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Screen Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildDailyChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        final dayStats = _dailyStats[DateTime(date.year, date.month, date.day)] ?? [];
        final totalTime = dayStats.fold<Duration>(
          Duration.zero,
          (total, stat) => total + stat.foregroundTime,
        );
        
        final maxTime = _dailyStats.values.fold<Duration>(
          Duration.zero,
          (max, stats) {
            final dayTotal = stats.fold<Duration>(
              Duration.zero,
              (total, stat) => total + stat.foregroundTime,
            );
            return dayTotal > max ? dayTotal : max;
          },
        );
        
        final height = maxTime.inMinutes > 0 
            ? (totalTime.inMinutes / maxTime.inMinutes) * 150 
            : 0.0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: height,
              decoration: BoxDecoration(
                color: Colors.blue[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${(totalTime.inMinutes / 60).toStringAsFixed(1)}h',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildWeekTopApps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Used Apps This Week',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_weekTopApps.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No usage data available for this week.'),
            ),
          )
        else
          ..._weekTopApps.map((app) => _buildAppUsageCard(app, _weekScreenTime)),
      ],
    );
  }

  Widget _buildAllAppsTab() {
    final List<AppUsageStats> filtered = _allAppsUsage.where((app) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return app.appName.toLowerCase().contains(q) || app.packageName.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Apps Usage',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search apps (name or package)...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showGlobalLimitDialog(),
            icon: const Icon(Icons.schedule),
            label: const Text('Screen limit'),
          ),
        ],
      ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search apps (name or package)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No apps match your search.'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  return _buildAppUsageCard(app, _weekScreenTime);
                },
                // Slightly larger cache extent for smoother scroll
                cacheExtent: 800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageCard(AppUsageStats app, Duration totalTime) {
    final limit = (_limits[app.packageName]?['dailyLimitMinutes'] ?? 0) as int;
    final percentage = app.getUsagePercentage(limit);
    final used = app.foregroundTime.inMinutes;
    final reached = limit > 0 && used >= limit;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reached ? Colors.red[100] : Colors.blue[100],
          child: Text(
            app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
            style: TextStyle(
              color: reached ? Colors.red[800] : Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          app.appName.isNotEmpty ? app.appName : app.packageName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: reached ? Colors.red[800] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${app.formattedUsageTime} • ${app.launchCount} launches'),
                if (limit > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: reached ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: reached ? Colors.red[200]! : Colors.green[200]!),
                    ),
                    child: Text(
                      reached ? 'Limit reached' : 'Limit: ${limit}m',
                      style: TextStyle(
                        fontSize: 11,
                        color: reached ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: limit > 0 ? (used / limit).clamp(0, 1).toDouble() : (percentage / 100),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                reached ? Colors.red : (limit > 0 ? Colors.green : Colors.blue),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              limit > 0
                  ? '$used/$limit min today'
                  : '${percentage.toStringAsFixed(1)}% of total time',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _buildLimitActions(app, limit, reached),
        onTap: () => _showSetLimitDialog(app),
      ),
    );
  }

  Widget _buildLimitActions(AppUsageStats app, int limit, bool reached) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Set limit',
          icon: const Icon(Icons.timer),
          onPressed: () => _showSetLimitDialog(app),
        ),
        if (limit > 0)
          IconButton(
            tooltip: 'Clear limit',
            icon: const Icon(Icons.clear),
            onPressed: () async {
              await _localStorage.setAppDailyLimit(app.packageName, 0);
              // Immediately unfreeze
              await _usageStatsService.clearAppRestriction(app.packageName);
              setState(() {
                _limits.remove(app.packageName);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Limit cleared')),
                );
              }
            },
          ),
      ],
    );
  }

  void _showSetLimitDialog(AppUsageStats app) async {
    final TextEditingController numberCtrl = TextEditingController();
    String unit = 'minutes';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Daily Limit for ${app.appName.isNotEmpty ? app.appName : app.packageName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: 'e.g. 60',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: unit,
                  items: const [
                    DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                    DropdownMenuItem(value: 'hours', child: Text('Hours')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      unit = v;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(numberCtrl.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid number of minutes')),
                );
                return;
              }
              final minutes = unit == 'hours' ? amount * 60 : amount;
              await _localStorage.setAppDailyLimit(app.packageName, minutes);
              setState(() {
                _limits[app.packageName] = {
                  'dailyLimitMinutes': minutes,
                  'usedMinutes': app.foregroundTime.inMinutes,
                  'lastReset': DateTime.now().toIso8601String(),
                };
              });
              // If previously restricted and new limit allows usage, unfreeze immediately
              if (app.foregroundTime.inMinutes < minutes) {
                await _usageStatsService.clearAppRestriction(app.packageName);
              }
              if (mounted) {
                Navigator.of(context).pop();
                final msg = unit == 'hours' ? 'Daily limit set: $amount hour(s)' : 'Daily limit set: $minutes min';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGlobalLimitDialog() {
    final TextEditingController numberCtrl = TextEditingController();
    String unit = 'minutes';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Global Daily Screen Limit'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'e.g. 120',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: unit,
              items: const [
                DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                DropdownMenuItem(value: 'hours', child: Text('Hours')),
              ],
              onChanged: (v) {
                if (v != null) {
                  unit = v;
                  (context as Element).markNeedsBuild();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(numberCtrl.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid number')),
                );
                return;
              }
              final minutes = unit == 'hours' ? amount * 60 : amount;
              await _localStorage.setGlobalDailyLimitMinutes(minutes);
              // If we previously had a global block and new limit allows usage now, clear it
              await _usageStatsService.clearGlobalRestriction();
              if (mounted) {
                Navigator.of(context).pop();
                final msg = unit == 'hours' ? 'Global limit set: $amount hour(s)' : 'Global limit set: $minutes min';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
