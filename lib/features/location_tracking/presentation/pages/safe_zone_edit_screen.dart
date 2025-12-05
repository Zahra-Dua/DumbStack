import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/di/service_locator.dart';
import 'package:parental_control_app/features/location_tracking/presentation/blocs/geofence/geofence_bloc.dart';

class SafeZoneEditScreen extends StatefulWidget {
  final String childId;
  final String childName;
  const SafeZoneEditScreen({super.key, required this.childId, required this.childName});

  @override
  State<SafeZoneEditScreen> createState() => _SafeZoneEditScreenState();
}

class _SafeZoneEditScreenState extends State<SafeZoneEditScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final TextEditingController _nameController = TextEditingController(text: 'Home');
  LatLng _center = const LatLng(33.6844, 73.0479);
  double _radius = 300;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final parentId = FirebaseAuth.instance.currentUser!.uid;
    return BlocProvider(
      create: (_) => sl<GeofenceBloc>()..add(GeofenceLoadChildLocation(widget.childId)),
      child: Scaffold(
        backgroundColor: AppColors.lightCyan,
        appBar: AppBar(
          backgroundColor: AppColors.lightCyan,
          elevation: 0,
          title: Text('Group ${widget.childName}'),
        ),
        body: BlocConsumer<GeofenceBloc, GeofenceState>(
          listener: (context, state) async {
            if (state.childLocation != null) {
              setState(() {
                _center = LatLng(state.childLocation!.latitude, state.childLocation!.longitude);
              });
              final controller = await _controller.future;
              controller.animateCamera(CameraUpdate.newLatLngZoom(_center, 14));
            } else if (state.createdZone != null) {
              if (mounted) Navigator.of(context).pop();
            } else if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(target: _center, zoom: 14),
                        circles: {
                          Circle(
                            circleId: const CircleId('zone'),
                            center: _center,
                            radius: _radius,
                            strokeColor: AppColors.darkCyan,
                            fillColor: AppColors.lightCyan.withOpacity(0.3),
                            strokeWidth: 2,
                          ),
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('center'),
                            position: _center,
                            draggable: true,
                            onDragEnd: (p) => setState(() => _center = p),
                          ),
                        },
                        onMapCreated: (c) => _controller.complete(c),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 90,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Radius'),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: _radius,
                                      min: 100,
                                      max: 2000,
                                      divisions: 19,
                                      label: '${_radius.toStringAsFixed(0)} m',
                                      onChanged: (v) => setState(() => _radius = v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: Text('${_radius.toStringAsFixed(0)} m'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.read<GeofenceBloc>().add(
                          GeofenceCreateRequested(
                            childId: widget.childId,
                            name: _nameController.text.trim().isEmpty ? 'Safe Zone' : _nameController.text.trim(),
                            centerLatitude: _center.latitude,
                            centerLongitude: _center.longitude,
                            radiusMeters: _radius,
                          ),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}