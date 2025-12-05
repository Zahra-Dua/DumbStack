import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/notification_bloc.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import 'recommendations_tab.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  String? _parentId;
  bool _isSelectionMode = false;
  final Set<String> _selectedNotifications = {};
  final NotificationRemoteDataSource _notificationDataSource = 
      NotificationRemoteDataSourceImpl(firestore: sl());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadParentId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadParentId() async {
    // Get parent ID from Firebase Auth
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final parentId = currentUser.uid;
      print('📡 [NotificationScreen] Parent ID loaded from Firebase Auth: $parentId');
      setState(() {
        _parentId = parentId;
      });
      // Only start streaming - it will load immediately and then update in real-time
      context.read<NotificationBloc>().add(StreamNotifications(parentId));
    } else {
      print('❌ [NotificationScreen] User not logged in');
      // Listen for auth state changes
      _auth.authStateChanges().listen((User? user) {
        if (user != null && mounted) {
          print('📡 [NotificationScreen] User logged in: ${user.uid}');
          setState(() {
            _parentId = user.uid;
          });
          // Only start streaming
          context.read<NotificationBloc>().add(StreamNotifications(user.uid));
        }
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(String notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
      if (_selectedNotifications.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelectedNotifications() async {
    if (_selectedNotifications.isEmpty || _parentId == null) return;

    try {
      // Get current notifications to find childId for each
      final state = context.read<NotificationBloc>().state;
      if (state is NotificationLoaded) {
        for (final notificationId in _selectedNotifications) {
          final notification = state.notifications.firstWhere(
            (n) => n.id == notificationId,
            orElse: () => state.notifications.first,
          );
          await _notificationDataSource.deleteNotification(
            _parentId!,
            notification.childId,
            notificationId,
          );
        }
      }

      setState(() {
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedNotifications.length} notification(s) deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    if (_parentId == null) return;

    try {
      // Get current notifications to find childId
      final state = context.read<NotificationBloc>().state;
      if (state is NotificationLoaded) {
        final notification = state.notifications.firstWhere(
          (n) => n.id == notificationId,
          orElse: () => state.notifications.first,
        );
        await _notificationDataSource.deleteNotification(
          _parentId!,
          notification.childId,
          notificationId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
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
        title: Text(_isSelectionMode 
            ? '${_selectedNotifications.length} Selected' 
            : 'Notifications'),
        backgroundColor: AppColors.lightCyan,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode)
            if (_selectedNotifications.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedNotifications,
                tooltip: 'Delete selected',
              )
            else
              const SizedBox.shrink()
          else
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                // Enter selection mode
                setState(() {
                  _isSelectionMode = true;
                });
              },
              tooltip: 'Select notifications',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications),
              text: 'Notifications',
            ),
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'Recommendations',
            ),
          ],
          indicatorColor: AppColors.darkCyan,
          labelColor: AppColors.textDark,
          unselectedLabelColor: AppColors.textLight,
        ),
      ),
      body: _parentId == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab(),
                RecommendationsTab(parentId: _parentId!),
              ],
            ),
    );
  }

  Widget _buildNotificationsTab() {
    return BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                print('📡 [NotificationScreen] Current state: ${state.runtimeType}');
                
                if (state is NotificationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is NotificationError) {
                  print('❌ [NotificationScreen] Error state: ${state.message}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<NotificationBloc>().add(
                                  StreamNotifications(_parentId!),
                                );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is NotificationLoaded) {
                  final notifications = state.notifications;

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<NotificationBloc>().add(
                            StreamNotifications(_parentId!),
                          );
                    },
                    child: ListView.builder(
                      itemCount: notifications.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isSelected = _selectedNotifications.contains(notification.id);
                        
                        return _buildNotificationCard(
                          notification: notification,
                          isSelected: isSelected,
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _toggleSelectionMode();
                            }
                            _toggleNotificationSelection(notification.id);
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleNotificationSelection(notification.id);
                            } else {
                              // Mark as read
                              context.read<NotificationBloc>().add(
                                    MarkAsRead(_parentId!, notification.childId, notification.id),
                                  );
                              
                              // Navigate based on actionUrl
                              final actionUrl = notification.actionUrl;
                              if (actionUrl != null) {
                                if (actionUrl == '/flagged-calls' || 
                                    actionUrl == '/calls/suspicious' ||
                                    actionUrl.contains('flagged') ||
                                    actionUrl.contains('suspicious')) {
                                  // Get child name from notification data or use default
                                  final childName = notification.data?['childName'] as String? ??
                                                   notification.data?['callerName'] as String? ??
                                                   'Child';
                                  
                                  // Flagged calls screen removed
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Flagged calls feature has been removed'),
                                    ),
                                  );
                                }
                                // Add more navigation cases here for other actionUrls
                              }
                            }
                          },
                          onDelete: () => _deleteNotification(notification.id),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            );
  }

  Widget _buildNotificationCard({
    required notification,
    required bool isSelected,
    required VoidCallback onLongPress,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final iconColor = _getColorForAlertType(notification.alertType);
    final isUnread = !notification.isRead;
    final dateTime = DateFormat('MMM d, y • h:mm a').format(notification.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isUnread ? 2 : 1,
      color: isSelected 
          ? AppColors.darkCyan.withOpacity(0.1) 
          : (isUnread ? Colors.white : Colors.grey[50]),
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      _toggleNotificationSelection(notification.id);
                    },
                    activeColor: AppColors.darkCyan,
                  ),
                ),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForAlertType(notification.alertType),
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!_isSelectionMode && isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.darkCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateTime,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Delete button (only when not in selection mode)
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.grey[600],
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForAlertType(alertType) {
    final typeString = alertType.toString().split('.').last;
    switch (typeString) {
      case 'suspiciousMessage':
        return Icons.message;
      case 'suspiciousCall':
        return Icons.phone;
      case 'geofencing':
        return Icons.location_on;
      case 'sos':
        return Icons.emergency;
      case 'screenTimeLimit':
        return Icons.timer;
      case 'appWebsiteBlocked':
        return Icons.block;
      case 'emotionalDistress':
        return Icons.mood_bad;
      case 'toxicBehaviorPattern':
        return Icons.warning;
      case 'suspiciousContactsPattern':
        return Icons.contacts;
      case 'predictiveThreat':
        return Icons.psychology;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForAlertType(alertType) {
    final typeString = alertType.toString().split('.').last;
    switch (typeString) {
      case 'sos':
        return Colors.red;
      case 'suspiciousMessage':
      case 'suspiciousCall':
        return Colors.orange;
      case 'geofencing':
        return Colors.blue;
      case 'emotionalDistress':
      case 'toxicBehaviorPattern':
        return Colors.purple;
      case 'predictiveThreat':
        return Colors.deepOrange;
      default:
        return AppColors.darkCyan;
    }
  }
}
