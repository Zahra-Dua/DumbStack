import 'package:flutter/material.dart';
import '../../../app_limits/data/models/installed_app_firebase.dart';

/// Installed Apps Tab Content Widget
/// 
/// Shows complete list of all installed apps on child's device
/// Features:
/// - Search functionality
/// - Filter by: All Apps, User Apps, System Apps, New Apps
/// - Shows app details: name, package, version, install date
/// - Real-time updates from Firebase
class InstalledAppsTabContent extends StatefulWidget {
  final List<InstalledAppFirebase> allApps;
  final List<InstalledAppFirebase> newApps;
  final List<InstalledAppFirebase> userApps;
  final List<InstalledAppFirebase> systemApps;
  final String childId;
  final String parentId;

  const InstalledAppsTabContent({
    required this.allApps,
    required this.newApps,
    required this.userApps,
    required this.systemApps,
    required this.childId,
    required this.parentId,
  });

  @override
  State<InstalledAppsTabContent> createState() => _InstalledAppsTabContentState();
}

class _InstalledAppsTabContentState extends State<InstalledAppsTabContent> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'user', 'system', 'new'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InstalledAppFirebase> get _filteredApps {
    List<InstalledAppFirebase> appsToShow;

    // Filter by type
    switch (_filterType) {
      case 'user':
        appsToShow = widget.userApps;
        break;
      case 'system':
        appsToShow = widget.systemApps;
        break;
      case 'new':
        appsToShow = widget.newApps;
        break;
      default:
        appsToShow = widget.allApps;
    }

    // Filter by search query
    if (_searchQuery.isEmpty) {
      return appsToShow;
    }

    final query = _searchQuery.toLowerCase();
    return appsToShow.where((app) {
      return app.appName.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('📊 [InstalledAppsTabContent] Building with:');
    print('   Total Apps: ${widget.allApps.length}');
    print('   User Apps: ${widget.userApps.length}');
    print('   System Apps: ${widget.systemApps.length}');
    print('   New Apps: ${widget.newApps.length}');
    
    return Column(
      children: [
        // Summary Card
        Container(
          padding: EdgeInsets.all(16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Apps',
                      widget.allApps.length.toString(),
                      Colors.blue,
                      Icons.apps,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'User Apps',
                      widget.userApps.length.toString(),
                      Colors.green,
                      Icons.person,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'System Apps',
                      widget.systemApps.length.toString(),
                      Colors.grey,
                      Icons.settings,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'New Apps',
                      widget.newApps.length.toString(),
                      Colors.orange,
                      Icons.new_releases,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Search and Filter Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
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
              SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list),
                tooltip: 'Filter Apps',
                onSelected: (value) {
                  setState(() {
                    _filterType = value;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(Icons.apps, size: 20),
                        SizedBox(width: 8),
                        Text('All Apps'),
                        if (_filterType == 'all')
                          Spacer(),
                        if (_filterType == 'all')
                          Icon(Icons.check, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'user',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('User Apps'),
                        if (_filterType == 'user')
                          Spacer(),
                        if (_filterType == 'user')
                          Icon(Icons.check, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'system',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 8),
                        Text('System Apps'),
                        if (_filterType == 'system')
                          Spacer(),
                        if (_filterType == 'system')
                          Icon(Icons.check, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'new',
                    child: Row(
                      children: [
                        Icon(Icons.new_releases, size: 20),
                        SizedBox(width: 8),
                        Text('New Apps'),
                        if (_filterType == 'new')
                          Spacer(),
                        if (_filterType == 'new')
                          Icon(Icons.check, size: 16, color: Colors.blue),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    _filterType == 'user'
                        ? 'User Apps Only'
                        : _filterType == 'system'
                            ? 'System Apps Only'
                            : 'New Apps Only',
                  ),
                  avatar: Icon(
                    _filterType == 'user'
                        ? Icons.person
                        : _filterType == 'system'
                            ? Icons.settings
                            : Icons.new_releases,
                    size: 18,
                  ),
                  onDeleted: () {
                    setState(() {
                      _filterType = 'all';
                    });
                  },
                  deleteIcon: Icon(Icons.close, size: 18),
                ),
              ],
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
                      SizedBox(height: 16),
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = _filteredApps[index];
                    return _buildInstalledAppCard(app);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInstalledAppCard(InstalledAppFirebase app) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showAppDetails(app),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // App Icon
              CircleAvatar(
                radius: 24,
                backgroundColor: app.isNewInstallation
                    ? Colors.green[100]
                    : app.isSystemApp
                        ? Colors.grey[200]
                        : Colors.blue[100],
                child: Icon(
                  app.isSystemApp ? Icons.settings : Icons.apps,
                  color: app.isNewInstallation
                      ? Colors.green[700]
                      : app.isSystemApp
                          ? Colors.grey[700]
                          : Colors.blue[700],
                  size: 24,
                ),
              ),
              SizedBox(width: 12),

              // App Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.appName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (app.isNewInstallation)
                          Container(
                            margin: EdgeInsets.only(left: 8),
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
                    SizedBox(height: 4),
                    Text(
                      app.packageName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (app.versionName != null) ...[
                          Icon(Icons.info_outline, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'v${app.versionName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        Icon(
                          app.isSystemApp ? Icons.settings : Icons.person,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          app.isSystemApp ? 'System' : 'User',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppDetails(InstalledAppFirebase app) {
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
              _buildDetailRow(
                'Detected At',
                _formatDate(app.detectedAt),
              ),
              if (app.isNewInstallation)
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.new_releases, color: Colors.green[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Newly Installed App',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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

