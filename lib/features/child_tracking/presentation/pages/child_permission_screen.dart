import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/real_data_collection_service.dart';
import '../../../url_tracking/data/datasources/url_tracking_service.dart';
import '../../../call_logging/data/datasources/call_log_remote_datasource.dart';

class ChildPermissionScreen extends StatefulWidget {
  const ChildPermissionScreen({super.key});

  @override
  State<ChildPermissionScreen> createState() => _ChildPermissionScreenState();
}

class _ChildPermissionScreenState extends State<ChildPermissionScreen> {
  bool _isLoading = false;
  final List<PermissionStatus> _permissionStatuses = [];
  final RealDataCollectionService _dataService = RealDataCollectionService();
  final UrlTrackingService _realUrlService = UrlTrackingService();
  bool _dataCollectionStarted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    
    final permissions = [
      Permission.systemAlertWindow,
      Permission.ignoreBatteryOptimizations,
      Permission.notification,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      _permissionStatuses.add(status);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Accessibility service permission handled through settings
      
      // Request system alert window permission
      await Permission.systemAlertWindow.request();
      
      // Request battery optimization ignore permission
      await Permission.ignoreBatteryOptimizations.request();
      
      // Request notification permission
      await Permission.notification.request();
      
      // Request usage stats permission (special handling)
      await _requestUsageStatsPermission();
      
      // Refresh permission statuses
      await _checkPermissions();

      // Start automatic data collection after permissions granted
      await _startAutomaticDataCollection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions granted! Data collection started automatically.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _requestUsageStatsPermission() async {
    // For usage stats, we need to open settings
    await openAppSettings();
  }

  // Start automatic data collection after permissions are granted
  Future<void> _startAutomaticDataCollection() async {
    try {
      if (_dataCollectionStarted) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in for data collection');
        return;
      }

      print('🚀 Starting automatic data collection...');
      
      // Start real URL tracking service
      await _realUrlService.startTracking();
      print('✅ Real URL tracking service started');

      // Start call logs monitoring
      final callLogDataSource = CallLogRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      );
      callLogDataSource.startContinuousMonitoring(
        parentId: currentUser.uid, // This should be actual parent ID in real app
        childId: currentUser.uid,
      );
      print('✅ Call logs monitoring started');

      // Initialize real data collection
      await _dataService.initializeRealDataCollection(
        childId: currentUser.uid,
        parentId: currentUser.uid, // This should be actual parent ID in real app
      );

      // Also simulate some initial data for immediate testing
      await _dataService.simulateRealDataCollection(
        childId: currentUser.uid,
        parentId: currentUser.uid,
      );

      setState(() {
        _dataCollectionStarted = true;
      });

      print('✅ Automatic data collection started successfully!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Data collection started! Parent can now see your activity.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error starting automatic data collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting data collection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Permissions'),
        backgroundColor: Colors.blue[100],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This app needs the following permissions to monitor your device usage:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPermissionCard(
                    icon: Icons.accessibility,
                    title: 'Accessibility Service',
                    description: 'Required to track app usage and URLs',
                    isGranted: false, // Accessibility service checked separately
                    onTap: () => _requestPermissions(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPermissionCard(
                    icon: Icons.system_update,
                    title: 'System Alert Window',
                    description: 'Required for overlay features',
                    isGranted: _permissionStatuses.isNotEmpty && 
                               _permissionStatuses[0] == PermissionStatus.granted,
                    onTap: () => _requestPermissions(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPermissionCard(
                    icon: Icons.battery_charging_full,
                    title: 'Battery Optimization',
                    description: 'Required to run in background',
                    isGranted: _permissionStatuses.length > 1 && 
                               _permissionStatuses[1] == PermissionStatus.granted,
                    onTap: () => _requestPermissions(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPermissionCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    description: 'Required for alerts and monitoring',
                    isGranted: _permissionStatuses.length > 2 && 
                               _permissionStatuses[2] == PermissionStatus.granted,
                    onTap: () => _requestPermissions(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _requestPermissions,
                      icon: const Icon(Icons.security),
                      label: const Text('Request All Permissions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Data Collection Status
                  if (_dataCollectionStarted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Collection Active',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const Text(
                                  'Your activity is being monitored and shared with parent',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Test buttons for debugging
                  if (_dataCollectionStarted) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _realUrlService.testAddUrl('https://www.google.com');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📊 Test URL uploaded to Firebase!'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Test Firebase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _realUrlService.testAddUrl('https://www.google.com');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🧪 Test URL added!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.link),
                            label: const Text('Test URL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Note: Some permissions may require manual approval in device settings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGranted ? Colors.green : Colors.orange,
          child: Icon(
            isGranted ? Icons.check : icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isGranted ? Colors.green[700] : Colors.orange[700],
          ),
        ),
        subtitle: Text(description),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
