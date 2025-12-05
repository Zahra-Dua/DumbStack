import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/services/child_app_initialization_service.dart';
import '../../data/datasources/message_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../child_tracking/presentation/pages/real_data_test_screen.dart';
import '../../../app_limits/data/services/real_time_app_usage_service.dart';

class ChildAppMainScreen extends StatefulWidget {
  const ChildAppMainScreen({super.key});

  @override
  State<ChildAppMainScreen> createState() => _ChildAppMainScreenState();
}

class _ChildAppMainScreenState extends State<ChildAppMainScreen> {
  late ChildAppInitializationService _initializationService;
  bool _isInitializing = true;
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _statusMessage = 'Requesting permissions...';
      });

      // Initialize the service
      _initializationService = ChildAppInitializationService(
        messageDataSource: MessageRemoteDataSourceImpl(
          firestore: FirebaseFirestore.instance,
        ),
      );

      // Initialize the app
      await _initializationService.initializeChildApp();

      setState(() {
        _isInitializing = false;
        _isInitialized = true;
        _statusMessage = 'App initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _isInitialized = false;
        _statusMessage = 'Initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        title: const Text('Child App'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(mq.w(0.08)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Icon
              Icon(
                _isInitializing
                    ? Icons.settings
                    : _isInitialized
                        ? Icons.check_circle
                        : Icons.error,
                size: 80,
                color: _isInitializing
                    ? Colors.blue
                    : _isInitialized
                        ? Colors.green
                        : Colors.red,
              ),
              
              SizedBox(height: mq.h(0.04)),
              
              // Status Message
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: mq.sp(0.05),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: mq.h(0.04)),
              
              // Loading indicator
              if (_isInitializing)
                const CircularProgressIndicator()
              else if (_isInitialized) ...[
                // Success state
                Container(
                  padding: EdgeInsets.all(mq.w(0.04)),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '✅ All services active',
                        style: TextStyle(
                          fontSize: mq.sp(0.04),
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: mq.h(0.01)),
                      Text(
                        'Location tracking and message monitoring are running',
                        style: TextStyle(
                          fontSize: mq.sp(0.035),
                          color: Colors.green[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: mq.h(0.04)),
                
                // Action buttons
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final status = await _initializationService.getPermissionStatus();
                            _showPermissionStatus(context, status);
                          },
                          icon: const Icon(Icons.security),
                          label: const Text('Check Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkCyan,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _initializationService.stopAllServices();
                            setState(() {
                              _isInitialized = false;
                              _statusMessage = 'Services stopped';
                            });
                          },
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Services'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: mq.h(0.02)),
                    
                    // Manual Sync Installed Apps Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _manualSyncInstalledApps();
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Installed Apps Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: mq.h(0.02)),
                    
                    // Real Data Collection Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RealDataTestScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.data_usage),
                        label: const Text('Start Real Data Collection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Error state
                Container(
                  padding: EdgeInsets.all(mq.w(0.04)),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '❌ Initialization failed',
                        style: TextStyle(
                          fontSize: mq.sp(0.04),
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: mq.h(0.01)),
                      Text(
                        'Please check permissions and try again',
                        style: TextStyle(
                          fontSize: mq.sp(0.035),
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: mq.h(0.04)),
                
                // Retry button
                ElevatedButton.icon(
                  onPressed: _initializeApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCyan,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _manualSyncInstalledApps() async {
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
              Text('Syncing installed apps...'),
            ],
          ),
        ),
      );

      // Get IDs
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parent_uid');
      final childId = prefs.getString('child_uid');

      if (parentId == null || childId == null) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Parent or Child ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create service and sync
      final service = RealTimeAppUsageService();
      service.initialize(childId: childId, parentId: parentId);
      await service.syncInstalledAppsNow();

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Installed apps synced successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionStatus(BuildContext context, Map<String, bool> status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPermissionRow('SMS', status['sms'] ?? false),
            _buildPermissionRow('Phone', status['phone'] ?? false),
            _buildPermissionRow('Notifications', status['notification'] ?? false),
            _buildPermissionRow('System Alert', status['systemAlert'] ?? false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String name, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _initializationService.dispose();
    super.dispose();
  }
}
