import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/services/location_tracking_service.dart';
import '../../data/datasources/location_remote_datasource.dart';
import '../../data/models/location_model.dart';

class AllChildrenMapScreen extends StatefulWidget {
  const AllChildrenMapScreen({super.key});

  @override
  State<AllChildrenMapScreen> createState() => _AllChildrenMapScreenState();
}

class _AllChildrenMapScreenState extends State<AllChildrenMapScreen> {
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _children = [];
  final Map<String, LocationModel?> _childLocations = {};
  final Set<Marker> _markers = {};
  final Set<Circle> _geofenceCircles = {};
  bool _isLoading = true;
  late LocationTrackingService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = LocationTrackingService(
      locationDataSource: LocationRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      ),
    );
    _loadChildrenAndLocations();
    
    // Add debug markers for emulator testing
    _addDebugMarkers();
  }

  void _addDebugMarkers() {
    // Add some debug markers for emulator testing
    _markers.add(
      const Marker(
        markerId: MarkerId('debug_1'),
        position: LatLng(33.6844, 73.0479), // Islamabad
        infoWindow: InfoWindow(
          title: 'Debug Location 1',
          snippet: 'Test marker for emulator',
        ),
      ),
    );
    
    _markers.add(
      const Marker(
        markerId: MarkerId('debug_2'),
        position: LatLng(33.6944, 73.0579), // Islamabad + offset
        infoWindow: InfoWindow(
          title: 'Debug Location 2',
          snippet: 'Test marker for emulator',
        ),
      ),
    );
  }

  Future<void> _loadChildrenAndLocations() async {
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
      });

      // Load locations for all children
      await _loadChildLocations();
      
      // Load geofence circles
      await _loadGeofenceCircles();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading children: $e')),
      );
    }
  }

  Future<void> _loadChildLocations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _markers.clear();
    
    for (final child in _children) {
      try {
        final location = await _locationService.getChildCurrentLocation(
          parentId: currentUser.uid,
          childId: child['id'],
        );
        
        if (location != null) {
          _childLocations[child['id']] = location;
          
          // Add marker for this child
          _markers.add(
            Marker(
              markerId: MarkerId(child['id']),
              position: LatLng(location.latitude, location.longitude),
              infoWindow: InfoWindow(
                title: child['name'],
                snippet: location.address,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(child['gender']),
              ),
            ),
          );
        }
      } catch (e) {
        print('Error loading location for ${child['name']}: $e');
      }
    }
    
    setState(() {});
    
    // Move camera to show all markers
    if (_markers.isNotEmpty) {
      _fitMarkersInView();
    }
  }

  Future<void> _loadGeofenceCircles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _geofenceCircles.clear();
    
    for (final child in _children) {
      try {
        // TODO: Load geofence settings from Firebase
        // For now, adding sample geofence circles
        if (child['name'] == 'beti' || child['name'] == 'ume') {
          _geofenceCircles.add(
            Circle(
              circleId: CircleId('geofence_${child['id']}'),
              center: LatLng(33.6844, 73.0479), // Sample location
              radius: 1000.0, // 1km radius
              fillColor: AppColors.darkCyan.withOpacity(0.2),
              strokeColor: AppColors.darkCyan,
              strokeWidth: 2,
            ),
          );
        }
      } catch (e) {
        print('Error loading geofence for ${child['name']}: $e');
      }
    }
    
    setState(() {});
  }

  double _getMarkerColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'female':
        return BitmapDescriptor.hueViolet;
      case 'male':
        return BitmapDescriptor.hueBlue;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  void _fitMarkersInView() {
    if (_mapController == null || _markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (final marker in _markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightCyan,
        appBar: AppBar(
          title: const Text('All Children Map'),
          backgroundColor: AppColors.lightCyan,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        title: const Text('All Children Map'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChildrenAndLocations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Children Status Bar
          if (_children.isNotEmpty) ...[
            Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: mq.w(0.04)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _children.length,
                itemBuilder: (context, index) {
                  final child = _children[index];
                  final location = _childLocations[child['id']];
                  final isOnline = location != null;
                  
                  return Container(
                    width: 120,
                    margin: EdgeInsets.only(right: mq.w(0.03)),
                    padding: EdgeInsets.all(mq.w(0.03)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: mq.w(0.02)),
                            Expanded(
                              child: Text(
                                child['name'],
                                style: TextStyle(
                                  fontSize: mq.sp(0.035),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: mq.h(0.005)),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: mq.sp(0.03),
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: mq.h(0.02)),
          ],

          // Map
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: mq.w(0.04)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _children.isEmpty 
                  ? _buildEmptyState(mq)
                  : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_markers.isNotEmpty) {
                      _fitMarkersInView();
                    }
                  },
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(33.6844, 73.0479), // Islamabad
                    zoom: 12.0,
                  ),
                  // Emulator compatibility
                  onTap: (LatLng position) {
                    print('Map tapped at: $position');
                  },
                  markers: _markers,
                  circles: _geofenceCircles,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),

          SizedBox(height: mq.h(0.02)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(MQ mq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: mq.h(0.02)),
            Text(
              'No children found',
              style: TextStyle(
                fontSize: mq.sp(0.05),
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: mq.h(0.01)),
            Text(
              'Add children to see their locations',
              style: TextStyle(
                fontSize: mq.sp(0.04),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
