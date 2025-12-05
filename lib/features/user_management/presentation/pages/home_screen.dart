import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parental_control_app/features/user_management/presentation/pages/parent_qr_screen.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/core/utils/error_message_helper.dart';
import 'package:parental_control_app/core/design_system/app_design_system.dart';
import 'package:parental_control_app/core/widgets/modern_card.dart';
import 'package:parental_control_app/core/widgets/modern_app_bar.dart';
import 'package:parental_control_app/core/widgets/modern_empty_state.dart';
import 'package:parental_control_app/core/di/service_locator.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/get_parent_children_usecase.dart';
import 'package:parental_control_app/features/location_tracking/presentation/pages/all_children_map_screen.dart';
import 'package:parental_control_app/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:parental_control_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/child_data_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'parent_settings_screen.dart';
import 'child_detail_screen.dart';
import 'package:parental_control_app/features/chatbot/presentation/pages/chatbot_screen.dart';
import 'package:parental_control_app/features/notifications/data/services/firestore_notification_listener.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  StreamSubscription<QuerySnapshot>? _childrenStream;
  FirestoreNotificationListener? _notificationListener;

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _setupRealtimeListener();
    _startNotificationListener();
  }

  @override
  void dispose() {
    _childrenStream?.cancel();
    _notificationListener?.stopListening();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final usecase = sl<GetParentChildrenUseCase>();
        final children = await usecase(parentUid: currentUser.uid);
        setState(() {
          _children = children;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      String errorMessage;
      if (ErrorMessageHelper.isNetworkError(e)) {
        errorMessage = ErrorMessageHelper.networkErrorRetrieval;
      } else {
        errorMessage = 'Error loading children: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Start Firestore notification listener (NO Cloud Functions needed)
  Future<void> _startNotificationListener() async {
    try {
      _notificationListener = FirestoreNotificationListener();
      await _notificationListener!.startListening();
      print('✅ [ParentHome] Firestore notification listener started');
    } catch (e) {
      print('❌ [ParentHome] Error starting notification listener: $e');
    }
  }

  void _setupRealtimeListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _childrenStream = FirebaseFirestore.instance
          .collection('parents')
          .doc(currentUser.uid)
          .collection('children')
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        print('🔄 [ParentHome] Real-time update: ${snapshot.docs.length} children');
        
        final children = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'uid': doc.id,
            'name': data['name'] ?? 'Unknown',
            'age': data['age'],
            'gender': data['gender'],
            'hobbies': data['hobbies'],
            'createdAt': data['createdAt'],
          };
        }).toList();
        
        // Sort by createdAt descending (newest first)
        children.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending order
        });

        setState(() {
          _children = children;
          _isLoading = false;
        });

        // Show notification if new child was added
        if (children.isNotEmpty) {
          final newChild = children.last;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.child_care, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('New child connected: ${newChild['name']}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      });
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      // Navigate to all children map screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AllChildrenMapScreen(),
        ),
      );
    } else if (index == 3) {
      // Navigate to insights screen (ChatbotScreen)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ChatbotScreen(),
        ),
      );
    } else if (index == 4) {
      // Navigate to settings screen
        Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => const ParentSettingsScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: ModernAppBar(
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textDark,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => sl<NotificationBloc>(),
                    child: const NotificationsScreen(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ParentSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingL,
            vertical: AppDesignSystem.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Padding(
                padding: const EdgeInsets.only(
                  top: AppDesignSystem.spacingM,
                  bottom: AppDesignSystem.spacingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Parent',
                      style: AppDesignSystem.headline1,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingS),
                    Text(
                      'Keep your children safe and connected',
                      style: AppDesignSystem.bodyLarge.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Generate QR Code Card (only show when no children)
              if (_children.isEmpty)
                ModernCard(
                  backgroundColor: AppColors.darkCyan,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentQRScreen(),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 32,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDesignSystem.spacingM),
                      Text(
                        "Generate QR Code",
                        style: AppDesignSystem.headline3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDesignSystem.spacingS),
                      Text(
                        "Create a QR code for your child to scan and join",
                        style: AppDesignSystem.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDesignSystem.spacingL),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDesignSystem.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusM,
                          ),
                        ),
                        child: Text(
                          "Generate QR",
                          style: AppDesignSystem.labelLarge.copyWith(
                            color: AppColors.darkCyan,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_children.isEmpty)
                const SizedBox(height: AppDesignSystem.spacingXL),

              // Connected Children Section
              Text(
                "Connected Children",
                style: AppDesignSystem.headline2,
              ),
              const SizedBox(height: AppDesignSystem.spacingM),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDesignSystem.spacingXXL),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_children.isEmpty)
                ModernEmptyState(
                  icon: Icons.child_care_rounded,
                  title: "No children connected yet",
                  subtitle: "Generate a QR code and have your child scan it to get started",
                )
              else
                Column(
                  children: [
                    // Children Profiles Horizontal List
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _children.length + 1, // +1 for Add Child button
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          if (index == _children.length) {
                            // Add Child Button
                            return Container(
                              margin: const EdgeInsets.only(
                                right: AppDesignSystem.spacingM,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  if (_children.length >= 5) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          'Child Limit Reached',
                                          style: AppDesignSystem.headline3,
                                        ),
                                        content: Text(
                                          'You cannot add more than 5 children.',
                                          style: AppDesignSystem.bodyMedium,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppDesignSystem.radiusL,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text(
                                              'OK',
                                              style: AppDesignSystem.labelLarge
                                                  .copyWith(
                                                color: AppColors.darkCyan,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ParentQRScreen(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.darkCyan,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.darkCyan
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: AppColors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: AppDesignSystem.spacingS),
                                    Text(
                                      'Add Child',
                                      style: AppDesignSystem.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final child = _children[index];
                          return Container(
                            margin: const EdgeInsets.only(
                              right: AppDesignSystem.spacingM,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChildDetailScreen(
                                      childId: child['id'] ?? child['uid'] ?? '',
                                      childName: child['name'] ?? 'Unknown',
                                      parentId: FirebaseAuth.instance.currentUser!.uid,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppColors.darkCyan,
                                    child: Text(
                                      child['name']?[0]?.toUpperCase() ?? 'C',
                                      style: AppDesignSystem.headline3.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppDesignSystem.spacingS),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      child['name'] ?? 'Unknown',
                                      style: AppDesignSystem.labelMedium,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXL),

                    // Children's Activity
                    Text(
                      "Children's Activity",
                      style: AppDesignSystem.headline2,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingM),
                    // Child Data Cards
                    ..._children.map((child) => ChildDataCard(
                          childId: child['id'] ?? child['uid'] ?? '',
                          childName: child['name'] ?? 'Unknown',
                          parentId: FirebaseAuth.instance.currentUser!.uid,
                          onChildDeleted: () {
                            // Refresh the children list when a child is deleted
                            _loadChildren();
                          },
                          onChildUpdated: () {
                            // Refresh the children list when a child is updated
                            _loadChildren();
                          },
                        )),

                    const SizedBox(height: AppDesignSystem.spacingXL),

                    // Children's Location
                    Text(
                      "Children's Location",
                      style: AppDesignSystem.headline2,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingM),
                    ModernCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllChildrenMapScreen(),
                          ),
                        );
                      },
                      child: SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_rounded,
                                size: AppDesignSystem.iconSizeXL,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: AppDesignSystem.spacingM),
                              Text(
                                'Map View',
                                style: AppDesignSystem.headline3.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: AppDesignSystem.spacingS),
                              Text(
                                'Tap to view all children on map',
                                style: AppDesignSystem.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDesignSystem.spacingXL),

                    // Recent Alerts
                    Text(
                      "Recent Alerts",
                      style: AppDesignSystem.headline2,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingM),
                    ModernCard(
                      child: Column(
                        children: [
                          _buildAlertItem(
                            'Emily visited a new website',
                            Icons.language_rounded,
                          ),
                          const Divider(height: AppDesignSystem.spacingL),
                          _buildAlertItem(
                            'John left the designated safe zone',
                            Icons.location_off_rounded,
                          ),
                          const Divider(height: AppDesignSystem.spacingL),
                          _buildAlertItem(
                            'Emily reached daily screen time limit',
                            Icons.schedule_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppDesignSystem.spacingXL),
            ],
          ),
        ),
      ),
     
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          selectedItemColor: AppColors.darkCyan,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: AppDesignSystem.labelSmall,
          unselectedLabelStyle: AppDesignSystem.labelSmall,
          backgroundColor: AppColors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotScreen(),
            ),
          );
        },
        backgroundColor: AppColors.darkCyan,
        elevation: AppDesignSystem.elevationHigh,
        child: const Icon(
          Icons.smart_toy_rounded,
          color: AppColors.white,
        ),
        tooltip: 'AI Recommendations & Insights',
      ),
    );
  }

  Widget _buildAlertItem(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.spacingS),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
            ),
            child: Icon(
              icon,
              color: AppColors.warning,
              size: AppDesignSystem.iconSizeM,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacingM),
          Expanded(
            child: Text(
              message,
              style: AppDesignSystem.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
