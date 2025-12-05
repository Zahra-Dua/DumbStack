import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../widgets/child_location_card.dart';
import '../widgets/location_map_widget.dart';
import '../../data/services/location_tracking_service.dart';
import '../../data/models/location_model.dart';
import '../../data/datasources/location_remote_datasource.dart';

class ParentLocationScreen extends StatefulWidget {
  const ParentLocationScreen({super.key});

  @override
  State<ParentLocationScreen> createState() => _ParentLocationScreenState();
}

class _ParentLocationScreenState extends State<ParentLocationScreen> {
  final LocationTrackingService _locationService = LocationTrackingService(
    locationDataSource: LocationRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );
  
  List<Map<String, dynamic>> _children = [];
  final Map<String, LocationModel?> _childLocations = {};
  bool _isLoading = true;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get children from parent's subcollection
      final childrenSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(currentUser.uid)
          .collection('children')
          .get();

      final children = childrenSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'age': data['age'] ?? 0,
          'gender': data['gender'] ?? '',
        };
      }).toList();

      setState(() {
        _children = children;
        _isLoading = false;
      });

      // Load locations for all children
      await _loadChildLocations();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading children: $e')),
      );
    }
  }

  Future<void> _loadChildLocations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    for (final child in _children) {
      try {
        final location = await _locationService.getChildCurrentLocation(
          parentId: currentUser.uid,
          childId: child['id'],
        );
        
        setState(() {
          _childLocations[child['id']] = location;
        });
      } catch (e) {
        print('Error loading location for ${child['name']}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightCyan,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        title: const Text('Children Location'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Column(
        children: [
          // Children List
          if (_children.isNotEmpty) ...[
            Container(
              height: 120,
              padding: EdgeInsets.symmetric(horizontal: mq.w(0.04)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];
                  final location = _childLocations[child['id']];
                  final isSelected = _selectedChildId == child['id'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedChildId = child['id'];
                      });
                    },
                    child: ChildLocationCard(
                      childName: child['name'],
                      childAge: child['age'],
                      childGender: child['gender'],
                      location: location,
                      isSelected: isSelected,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: mq.h(0.02)),
          ],

          // Map or No Children Message
          Expanded(
            child: _children.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.child_care,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: mq.h(0.02)),
                        Text(
                          'No children linked yet',
                          style: TextStyle(
                            fontSize: mq.sp(0.05),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: mq.h(0.01)),
                        Text(
                          'Scan QR code to link a child',
                          style: TextStyle(
                            fontSize: mq.sp(0.04),
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _selectedChildId != null
                    ? LocationMapWidget(
                        childId: _selectedChildId!,
                        childName: _children.firstWhere((c) => c['id'] == _selectedChildId)['name'],
                        parentId: FirebaseAuth.instance.currentUser!.uid,
                        locationService: _locationService,
                      )
                    : Center(
                        child: Text(
                          'Select a child to view location',
                          style: TextStyle(
                            fontSize: mq.sp(0.05),
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
