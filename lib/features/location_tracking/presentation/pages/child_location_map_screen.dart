import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/constants/app_text_styles.dart';
import 'package:parental_control_app/core/di/service_locator.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';
import 'package:parental_control_app/features/location_tracking/presentation/blocs/map/map_bloc.dart';
import 'package:parental_control_app/features/location_tracking/presentation/widgets/child_location_info_card.dart';
import 'package:parental_control_app/features/location_tracking/presentation/widgets/geofence_zone_dialog.dart';

class ChildLocationMapScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildLocationMapScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildLocationMapScreen> createState() => _ChildLocationMapScreenState();
}

class _ChildLocationMapScreenState extends State<ChildLocationMapScreen> {
  GoogleMapController? _mapController;
  late final MapBloc _mapBloc;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  // Default location (Islamabad, Pakistan) if no child location available
  static const LatLng _defaultLocation = LatLng(33.6844, 73.0479);

  @override
  void initState() {
    super.initState();
    _mapBloc = sl<MapBloc>();
    _mapBloc.add(MapStartTracking(widget.childId));
  }

  @override
  void dispose() {
    _mapBloc.add(const MapStopTracking());
    _mapBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.childName}\'s Location',
              style: AppTextStyles.heading3.copyWith(color: Colors.white),
            ),
            BlocBuilder<MapBloc, MapState>(
              bloc: _mapBloc,
              builder: (context, state) {
                if (state.lastUpdated != null) {
                  return Text(
                    'Last updated: ${_formatTime(state.lastUpdated!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _mapBloc.add(MapStartTracking(widget.childId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
            onPressed: _showAddGeofenceDialog,
          ),
        ],
      ),
      body: BlocListener<MapBloc, MapState>(
        bloc: _mapBloc,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state.currentLocation != null) {
            _updateMapMarkers(state.currentLocation!, state.geofences);
          }
        },
        child: BlocBuilder<MapBloc, MapState>(
          bloc: _mapBloc,
          builder: (context, state) {
            return Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (state.currentLocation != null) {
                      _animateToLocation(
                        LatLng(
                          state.currentLocation!.latitude,
                          state.currentLocation!.longitude,
                        ),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: state.currentLocation != null
                        ? LatLng(
                            state.currentLocation!.latitude,
                            state.currentLocation!.longitude,
                          )
                        : _defaultLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onTap: (LatLng location) {
                    // Handle map tap for adding geofences
                    _showAddGeofenceDialog(location: location);
                  },
                ),

                // Child location info card
                if (state.currentLocation != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: ChildLocationInfoCard(
                      location: state.currentLocation!,
                      childName: widget.childName,
                    ),
                  ),

                // Loading indicator
                if (state.isTracking && state.currentLocation == null)
                  const Positioned.fill(
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading child location...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Floating action buttons
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: "center_location",
                        mini: true,
                        backgroundColor: AppColors.primary,
                        onPressed: _centerOnChildLocation,
                        child: const Icon(Icons.my_location, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "add_geofence",
                        mini: true,
                        backgroundColor: AppColors.secondary,
                        onPressed: _showAddGeofenceDialog,
                        child: const Icon(Icons.add_location, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Geofence zones list
                if (state.geofences.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: _buildGeofencesList(state.geofences),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateMapMarkers(
    ChildLocationEntity location,
    List<GeofenceZoneEntity> geofences,
  ) {
    setState(() {
      // Add child location marker
      _markers = {
        Marker(
          markerId: const MarkerId('child_location'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: widget.childName,
            snippet: 'Last seen: ${_formatTime(location.timestamp)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };

      // Add geofence circles
      _circles = geofences.map((geofence) {
        return Circle(
          circleId: CircleId(geofence.id),
          center: LatLng(geofence.centerLatitude, geofence.centerLongitude),
          radius: geofence.radiusMeters,
          fillColor: _parseColor(geofence.color).withOpacity(0.2),
          strokeColor: _parseColor(geofence.color),
          strokeWidth: 2,
        );
      }).toSet();
    });
  }

  Widget _buildGeofencesList(List<GeofenceZoneEntity> geofences) {
    return Container(
      width: 200,
      constraints: const BoxConstraints(maxHeight: 150),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Safe Zones',
                style: AppTextStyles.bodyBold,
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: geofences.length,
                itemBuilder: (context, index) {
                  final geofence = geofences[index];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _parseColor(geofence.color),
                      ),
                    ),
                    title: Text(
                      geofence.name,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${geofence.radiusMeters.round()}m radius',
                      style: AppTextStyles.caption,
                    ),
                    onTap: () => _centerOnGeofence(geofence),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _centerOnChildLocation() {
    final state = _mapBloc.state;
    if (state.currentLocation != null) {
      _animateToLocation(
        LatLng(
          state.currentLocation!.latitude,
          state.currentLocation!.longitude,
        ),
      );
    }
  }

  void _centerOnGeofence(GeofenceZoneEntity geofence) {
    _animateToLocation(
      LatLng(geofence.centerLatitude, geofence.centerLongitude),
    );
  }

  void _animateToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 15.0,
        ),
      ),
    );
  }

  void _showAddGeofenceDialog({LatLng? location}) {
    showDialog(
      context: context,
      builder: (context) => GeofenceZoneDialog(
        childId: widget.childId,
        initialLocation: location,
      ),
    ).then((result) {
      if (result == true) {
        // Refresh the geofences
        _mapBloc.add(MapStartTracking(widget.childId));
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary; // fallback color
    }
  }
}
