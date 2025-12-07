import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/design_system/app_design_system.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/modern_app_bar.dart';
import '../../../location_tracking/presentation/widgets/location_map_widget.dart';
import '../../../location_tracking/data/services/location_tracking_service.dart';
import '../../../location_tracking/data/datasources/location_remote_datasource.dart';
import '../../../location_tracking/presentation/widgets/geofence_settings_card.dart';
import '../../../location_tracking/presentation/pages/geofence_configuration_screen.dart';
import '../../../messaging/presentation/pages/flagged_messages_screen.dart';
import '../../../call_logging/presentation/pages/call_history_screen.dart';
import '../../../call_logging/presentation/pages/flagged_calls_screen.dart';
import '../../../call_logging/data/datasources/flagged_calls_remote_datasource.dart';
import '../../../call_logging/data/models/call_log_model.dart';
import '../../../parent_dashboard/presentation/pages/url_history_screen.dart';
import '../../../parent_dashboard/presentation/pages/app_usage_history_screen.dart';
import '../../../parent_dashboard/presentation/pages/screen_time_activity_screen.dart';
import '../../../reports/presentation/widgets/report_card_widget.dart';
import '../../../watch_list/presentation/pages/watch_list_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const ChildDetailScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _childData;
  bool _isLoading = true;
  int? _batteryLevel;
  late LocationTrackingService _locationService;
  StreamSubscription<DocumentSnapshot>? _childDataSubscription;
  final FlaggedCallsRemoteDataSource _flaggedCallsDataSource = FlaggedCallsRemoteDataSource(
    firestore: FirebaseFirestore.instance,
  );
  int _flaggedCallsCount = 0;
  StreamSubscription<List<CallLogModel>>? _flaggedCallsSubscription;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _locationService = LocationTrackingService(
      locationDataSource: LocationRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      ),
    );
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _loadChildData();
    _loadFlaggedCallsCount();
    _listenToFlaggedCalls();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animationController.forward();
    });
  }

  Future<void> _loadChildData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _childData = doc.data();
          _batteryLevel = doc.data()?['batteryLevel'] as int?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
      
      _childDataSubscription = FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>?;
          setState(() {
            _childData = data;
            _batteryLevel = data?['batteryLevel'] as int?;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading child data: $e')),
        );
      }
    }
  }

  Future<void> _loadFlaggedCallsCount() async {
    try {
      final count = await _flaggedCallsDataSource.getFlaggedCallsCount(
        parentId: widget.parentId,
        childId: widget.childId,
      );
      if (mounted) {
        setState(() {
          _flaggedCallsCount = count;
        });
      }
    } catch (e) {
      print('Error loading flagged calls count: $e');
    }
  }

  void _listenToFlaggedCalls() {
    _flaggedCallsSubscription = _flaggedCallsDataSource
        .getFlaggedCallsStream(
          parentId: widget.parentId,
          childId: widget.childId,
        )
        .listen((calls) {
      if (mounted) {
        setState(() {
          _flaggedCallsCount = calls.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _childDataSubscription?.cancel();
    _flaggedCallsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightCyan,
        appBar: ModernAppBar(title: widget.childName),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: ModernAppBar(
        title: '${widget.childName}\'s Phone',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildChildStatusCard(),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildMonitoringSection(),
            const SizedBox(height: 16),
            ReportCardWidget(
              childId: widget.childId,
              childName: widget.childName,
              parentId: widget.parentId,
            ),
            const SizedBox(height: 16),
            GeofenceSettingsCard(
              childId: widget.childId,
              childName: widget.childName,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeofenceConfigurationScreen(
                      childId: widget.childId,
                      childName: widget.childName,
                      parentId: widget.parentId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildChildInfoCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.darkCyan,
            child: Text(
              widget.childName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.childName}\'s Phone',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Active',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.battery_charging_full, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${_batteryLevel ?? 'N/A'}%',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.darkCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Live Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationMapWidget(
                        childId: widget.childId,
                        childName: widget.childName,
                        parentId: widget.parentId,
                        locationService: _locationService,
                      ),
                    ),
                  );
                },
                child: const Text('View Full'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LocationMapWidget(
                childId: widget.childId,
                childName: widget.childName,
                parentId: widget.parentId,
                locationService: _locationService,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.warning_rounded,
            iconColor: AppColors.error,
            title: 'Suspicious\nMessages',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlaggedMessagesScreen(
                    childId: widget.childId,
                    childName: widget.childName,
                    parentId: widget.parentId,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.call,
            iconColor: AppColors.darkCyan,
            title: 'Call\nHistory',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallHistoryScreen(
                    childId: widget.childId,
                    childName: widget.childName,
                    parentId: widget.parentId,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.phone_callback,
            iconColor: AppColors.error,
            title: 'Flagged\nCalls',
            badge: _flaggedCallsCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlaggedCallsScreen(
                    childId: widget.childId,
                    childName: widget.childName,
                    parentId: widget.parentId,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    int? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  if (badge != null && badge > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonitoringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Monitoring',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildMonitoringCard(
          icon: Icons.language,
          iconColor: AppColors.success,
          title: 'URL Tracking',
          subtitle: 'Monitor browsing activity',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UrlHistoryScreen(
                  urls: [],
                  childId: widget.childId,
                  parentId: widget.parentId,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMonitoringCard(
          icon: Icons.phone_android,
          iconColor: AppColors.brightTeal,
          title: 'App Usage',
          subtitle: 'Monitor app activity',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppUsageHistoryScreen(
                  apps: [],
                  childId: widget.childId,
                  parentId: widget.parentId,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMonitoringCard(
          icon: Icons.analytics,
          iconColor: AppColors.darkCyan,
          title: 'Screen Time Activity',
          subtitle: 'View detailed usage graphs',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScreenTimeActivityScreen(
                  childId: widget.childId,
                  childName: widget.childName,
                  parentId: widget.parentId,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMonitoringCard(
          icon: Icons.visibility,
          iconColor: AppColors.warning,
          title: 'Watch List',
          subtitle: 'Monitor specific contacts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WatchListScreen(
                  childId: widget.childId,
                  parentId: widget.parentId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonitoringCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Child Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_childData != null) ...[
            _buildInfoRow('Name', _childData!['name'] ?? 'Unknown'),
            const Divider(height: 24),
            _buildInfoRow('Age', _childData!['age']?.toString() ?? 'Unknown'),
            const Divider(height: 24),
            _buildInfoRow('Gender', _childData!['gender'] ?? 'Unknown'),
            if (_childData!['hobbies'] != null && (_childData!['hobbies'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Hobbies',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_childData!['hobbies'] as List).map<Widget>((hobby) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.darkCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hobby.toString(),
                      style: const TextStyle(
                        color: AppColors.darkCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Child information not available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

