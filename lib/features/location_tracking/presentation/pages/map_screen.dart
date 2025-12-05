import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/di/service_locator.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';
import 'package:parental_control_app/features/location_tracking/presentation/blocs/map/map_bloc.dart';
import 'package:parental_control_app/features/location_tracking/presentation/pages/safe_zone_edit_screen.dart';

class MapScreen extends StatefulWidget {
  final String childId;
  final String? childName;
  const MapScreen({super.key, required this.childId, this.childName});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MapBloc>()..add(MapStartTracking(widget.childId)),
      child: Scaffold(
        backgroundColor: AppColors.lightCyan,
        appBar: AppBar(
          title: Text(widget.childName ?? 'Location'),
          backgroundColor: AppColors.lightCyan,
          elevation: 0,
        ),
        body: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            LatLng? target;
            Set<Circle> circles = {};
            if (state.currentLocation != null) {
              if (state.currentLocation != null) {
                target = LatLng(state.currentLocation!.latitude, state.currentLocation!.longitude);
              }
              circles = _circlesFromZones(state.geofences);
            }
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: target ?? const LatLng(33.6844, 73.0479), zoom: 13),
                  myLocationEnabled: false,
                  circles: circles,
                  markers: target != null
                      ? {
                          Marker(
                            markerId: const MarkerId('child'),
                            position: target,
                          ),
                        }
                      : {},
                  onMapCreated: (controller) => _controller.complete(controller),
                ),
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SafeZoneEditScreen(childId: widget.childId, childName: widget.childName ?? ''),
                      ));
                    },
                    child: const Text('Edit Safe Zone'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Set<Circle> _circlesFromZones(List<GeofenceZoneEntity> zones) {
    return zones
        .where((z) => z.isActive)
        .map((z) => Circle(
              circleId: CircleId(z.id),
              center: LatLng(z.centerLatitude, z.centerLongitude),
              radius: z.radiusMeters,
              strokeColor: AppColors.darkCyan.withOpacity(0.8),
              fillColor: AppColors.lightCyan.withOpacity(0.3),
              strokeWidth: 2,
            ))
        .toSet();
  }
}