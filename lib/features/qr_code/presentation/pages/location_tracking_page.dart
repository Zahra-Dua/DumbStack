import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../user_management/data/models/parent_model.dart';
import '../../../user_management/data/models/child_model.dart';
import '../../../user_management/data/services/location_tracking_service.dart';

class LocationTrackingPage extends StatefulWidget {
  final ParentModel parent;
  final ChildModel child;

  const LocationTrackingPage({
    super.key,
    required this.parent,
    required this.child,
  });

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  final LocationTrackingService _locationService = LocationTrackingService();
  GoogleMapController? _mapController;
  ChildModel? _currentChild;
  Map<String, dynamic>? _locationStats;
  bool _isTracking = false;
  List<Map<String, dynamic>> _locationHistory = [];

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
    _loadLocationData();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadLocationData() async {
    try {
      // Load location stats
      final stats = await _locationService.getLocationStats(
        parentId: widget.parent.parentId,
        childId: widget.child.childId,
      );

      // Load location history
      final history = await _locationService.getLocationHistory(
        parentId: widget.parent.parentId,
        childId: widget.child.childId,
        limit: 20,
      );

      setState(() {
        _locationStats = stats;
        _locationHistory = history;
        _isTracking = _locationService.isTrackingActive;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading location data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location - ${widget.child.name}'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.location_on : Icons.location_off),
            onPressed: _toggleTracking,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLocationData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Stats
          if (_locationStats != null) _buildLocationStats(),
          
          // Map
          Expanded(
            child: _buildMap(),
          ),
          
          // Location History
          if (_locationHistory.isNotEmpty) _buildLocationHistory(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateCurrentLocation,
        backgroundColor: Colors.blue[700],
        child: Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildLocationStats() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Status',
                _currentChild?.currentLocationStatus?.toUpperCase() ?? 'UNKNOWN',
                _getStatusColor(_currentChild?.currentLocationStatus),
              ),
              _buildStatItem(
                'Last Update',
                _currentChild?.lastLocationUpdateText ?? 'Never',
                Colors.blue,
              ),
              _buildStatItem(
                'Accuracy',
                _currentChild?.locationAccuracyText ?? 'Unknown',
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Today',
                '${_locationStats!['todayLocations']} locations',
                Colors.orange,
              ),
              _buildStatItem(
                'Week',
                '${_locationStats!['weekLocations']} locations',
                Colors.purple,
              ),
              _buildStatItem(
                'Total',
                '${_locationStats!['totalLocations']} locations',
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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

  Widget _buildMap() {
    if (_currentChild?.hasCurrentLocation != true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No location data available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start tracking to see location',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentChild!.currentLatitude!,
          _currentChild!.currentLongitude!,
        ),
        zoom: 15.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Current location marker
    if (_currentChild?.hasCurrentLocation == true) {
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(
            _currentChild!.currentLatitude!,
            _currentChild!.currentLongitude!,
          ),
          infoWindow: InfoWindow(
            title: widget.child.name,
            snippet: _currentChild!.currentAddress ?? 'Current Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // History markers
    for (int i = 0; i < _locationHistory.length && i < 10; i++) {
      final location = _locationHistory[i];
      markers.add(
        Marker(
          markerId: MarkerId('history_$i'),
          position: LatLng(
            location['latitude'] as double,
            location['longitude'] as double,
          ),
          infoWindow: InfoWindow(
            title: 'Location ${i + 1}',
            snippet: location['address'] ?? 'Previous Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_locationHistory.length < 2) return {};

    final points = _locationHistory
        .map((loc) => LatLng(
              loc['latitude'] as double,
              loc['longitude'] as double,
            ))
        .toList();

    return {
      Polyline(
        polylineId: PolylineId('location_path'),
        points: points,
        color: Colors.blue,
        width: 3,
      ),
    };
  }

  Widget _buildLocationHistory() {
    return SizedBox(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _locationHistory.length,
              itemBuilder: (context, index) {
                final location = _locationHistory[index];
                final timestamp = DateTime.parse(location['timestamp']);
                
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue[700],
                      ),
                    ),
                    title: Text(
                      location['address'] ?? 'Unknown Address',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${location['latitude'].toStringAsFixed(4)}, ${location['longitude'].toStringAsFixed(4)}',
                    ),
                    trailing: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () => _goToLocation(
                      location['latitude'] as double,
                      location['longitude'] as double,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      case 'unknown':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _toggleTracking() async {
    try {
      if (_isTracking) {
        await _locationService.stopLocationTracking();
        setState(() {
          _isTracking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location tracking stopped')),
        );
      } else {
        await _locationService.startLocationTracking(
          parentId: widget.parent.parentId,
          childId: widget.child.childId,
        );
        setState(() {
          _isTracking = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location tracking started')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling tracking: $e')),
      );
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      await _locationService.updateCurrentLocation(
        parentId: widget.parent.parentId,
        childId: widget.child.childId,
      );
      await _loadLocationData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }

  Future<void> _goToLocation(double latitude, double longitude) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(latitude, longitude)),
      );
    }
  }
}
