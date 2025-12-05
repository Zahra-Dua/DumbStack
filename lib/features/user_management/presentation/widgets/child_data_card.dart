import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/utils/error_message_helper.dart';
import '../../../../core/design_system/app_design_system.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../location_tracking/data/models/location_model.dart';
import '../pages/child_detail_screen.dart';
import '../pages/edit_child_profile_screen.dart';
import '../../data/services/delete_child_service.dart';

class ChildDataCard extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;
  final VoidCallback? onChildDeleted;
  final VoidCallback? onChildUpdated;

  const ChildDataCard({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
    this.onChildDeleted,
    this.onChildUpdated,
  });

  @override
  State<ChildDataCard> createState() => _ChildDataCardState();
}

class _ChildDataCardState extends State<ChildDataCard> {
  LocationModel? _currentLocation;
  bool _isLoading = true;
  final DeleteChildService _deleteChildService = DeleteChildService();

  @override
  void initState() {
    super.initState();
    _loadChildLocation();
  }

  Future<void> _loadChildLocation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('location')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentLocation = LocationModel.fromMap(doc.data()!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editChild() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditChildProfileScreen(
          childId: widget.childId,
          parentId: widget.parentId,
        ),
      ),
    );

    // If update was successful, refresh the parent widget
    if (result == true && widget.onChildUpdated != null) {
      widget.onChildUpdated!();
    }
  }

  Future<void> _deleteChild() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Child'),
                    content: Text(
                      'Are you sure you want to delete ${widget.childName}? This action cannot be undone and will remove all data associated with this child.',
                      style: AppDesignSystem.bodyMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusL,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: AppDesignSystem.labelLarge.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Delete',
                          style: AppDesignSystem.labelLarge.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
        );
      },
    );

    if (confirmed == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting child...'),
              ],
            ),
          );
        },
      );

      try {
        final success = await _deleteChildService.deleteChild(
          parentId: widget.parentId,
          childId: widget.childId,
          childName: widget.childName, // Pass child name for notification
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.childName} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Notify parent widget to refresh
          if (widget.onChildDeleted != null) {
            widget.onChildDeleted!();
          }
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete child. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        String errorMessage;
        if (ErrorMessageHelper.isNetworkError(e)) {
          errorMessage = ErrorMessageHelper.networkErrorProfileDeletion;
        } else {
          errorMessage = 'Error deleting child: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailScreen(
              childId: widget.childId,
              childName: widget.childName,
              parentId: widget.parentId,
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(AppDesignSystem.spacingL),
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.darkCyan,
                child: Text(
                  widget.childName[0].toUpperCase(),
                  style: AppDesignSystem.headline3.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.childName,
                      style: AppDesignSystem.headline3,
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXS),
                    Text(
                      'Child',
                      style: AppDesignSystem.bodySmall,
                    ),
                  ],
                ),
              ),
              // Location Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacingM,
                  vertical: AppDesignSystem.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: _currentLocation != null
                      ? AppColors.success
                      : AppColors.textLight,
                  borderRadius: BorderRadius.circular(
                    AppDesignSystem.radiusRound,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacingS),
                    Text(
                      _currentLocation != null ? 'Online' : 'Offline',
                      style: AppDesignSystem.labelSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingS),
              // 3 Dots Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textLight,
                  size: AppDesignSystem.iconSizeM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                ),
                onSelected: (String value) {
                  if (value == 'edit') {
                    _editChild();
                  } else if (value == 'delete') {
                    _deleteChild();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: AppColors.darkCyan,
                          size: AppDesignSystem.iconSizeM,
                        ),
                        const SizedBox(width: AppDesignSystem.spacingM),
                        Text(
                          'Edit Profile',
                          style: AppDesignSystem.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          color: AppColors.error,
                          size: AppDesignSystem.iconSizeM,
                        ),
                        const SizedBox(width: AppDesignSystem.spacingM),
                        Text(
                          'Delete Child',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacingL),
            
          // Location Info
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDesignSystem.spacingL),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCyan),
                ),
              ),
            )
          else if (_currentLocation != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingM),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacingS),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusS,
                          ),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppColors.error,
                          size: AppDesignSystem.iconSizeM,
                        ),
                      ),
                      const SizedBox(width: AppDesignSystem.spacingM),
                      Expanded(
                        child: Text(
                          _currentLocation!.address,
                          style: AppDesignSystem.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignSystem.spacingM),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacingS),
                        decoration: BoxDecoration(
                          color: AppColors.darkCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesignSystem.radiusS,
                          ),
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: AppColors.darkCyan,
                          size: AppDesignSystem.iconSizeS,
                        ),
                      ),
                      const SizedBox(width: AppDesignSystem.spacingM),
                      Text(
                        'Last seen: ${_formatTime(_currentLocation!.timestamp)}',
                        style: AppDesignSystem.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingM),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusS,
                      ),
                    ),
                    child: Icon(
                      Icons.location_off_rounded,
                      color: AppColors.textLight,
                      size: AppDesignSystem.iconSizeM,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacingM),
                  Text(
                    'Location not available',
                    style: AppDesignSystem.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

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
