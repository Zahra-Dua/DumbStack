import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/services/location_tracking_service.dart';
import '../../data/models/location_model.dart';

class LocationMapWidget extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;
  final LocationTrackingService locationService;

  const LocationMapWidget({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
    required this.locationService,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  GoogleMapController? _mapController;
  LocationModel? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      // Get current location
      final location = await widget.locationService.getChildCurrentLocation(
        parentId: widget.parentId,
        childId: widget.childId,
      );

      if (location != null) {
        setState(() {
          _currentLocation = location;
          _markers = {
            Marker(
              markerId: MarkerId(widget.childId),
              position: LatLng(location.latitude, location.longitude),
              infoWindow: InfoWindow(
                title: widget.childName,
                snippet: location.address,
              ),
            ),
          };
        });

        // Move camera to location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(location.latitude, location.longitude),
            15.0,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: mq.h(0.02)),
            Text(
              'Loading location...',
              style: TextStyle(
                fontSize: mq.sp(0.04),
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: mq.h(0.02)),
            Text(
              'Location not available',
              style: TextStyle(
                fontSize: mq.sp(0.05),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: mq.h(0.01)),
            Text(
              'Child location tracking is disabled',
              style: TextStyle(
                fontSize: mq.sp(0.04),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Location Info Card
        Container(
          margin: EdgeInsets.all(mq.w(0.04)),
          padding: EdgeInsets.all(mq.w(0.04)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.darkCyan,
                    size: 24,
                  ),
                  SizedBox(width: mq.w(0.02)),
                  Text(
                    widget.childName,
                    style: TextStyle(
                      fontSize: mq.sp(0.05),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mq.w(0.03),
                      vertical: mq.h(0.005),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Online',
                      style: TextStyle(
                        fontSize: mq.sp(0.035),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mq.h(0.01)),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: mq.w(0.02)),
                  Expanded(
                    child: Text(
                      _currentLocation!.address,
                      style: TextStyle(
                        fontSize: mq.sp(0.04),
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mq.h(0.005)),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: mq.w(0.02)),
                  Text(
                    'Last updated: ${_formatTime(_currentLocation!.timestamp)}',
                    style: TextStyle(
                      fontSize: mq.sp(0.035),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

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
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  print('🗺️ [LocationMap] GoogleMap created successfully');
                },
                initialCameraPosition: CameraPosition(
                  target: _currentLocation != null 
                    ? LatLng(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                      )
                    : const LatLng(33.6844, 73.0479), // Islamabad default
                  zoom: 15.0,
                ),
                markers: _markers,
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
