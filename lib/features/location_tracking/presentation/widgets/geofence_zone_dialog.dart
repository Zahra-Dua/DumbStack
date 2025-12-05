import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/constants/app_text_styles.dart';
import 'package:parental_control_app/core/di/service_locator.dart';
import 'package:parental_control_app/features/location_tracking/presentation/blocs/geofence/geofence_bloc.dart';

class GeofenceZoneDialog extends StatefulWidget {
  final String childId;
  final LatLng? initialLocation;

  const GeofenceZoneDialog({
    super.key,
    required this.childId,
    this.initialLocation,
  });

  @override
  State<GeofenceZoneDialog> createState() => _GeofenceZoneDialogState();
}

class _GeofenceZoneDialogState extends State<GeofenceZoneDialog> {
  late final GeofenceBloc _geofenceBloc;
  GoogleMapController? _mapController;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  LatLng? _selectedLocation;
  double _radius = 200.0; // Default radius in meters
  String _selectedColor = '#4A90E2';
  
  final List<String> _colorOptions = [
    '#4A90E2', // Blue
    '#50C878', // Green  
    '#FF6B6B', // Red
    '#FFD93D', // Yellow
    '#9B59B6', // Purple
    '#FF8C42', // Orange
  ];

  @override
  void initState() {
    super.initState();
    _geofenceBloc = sl<GeofenceBloc>();
    _selectedLocation = widget.initialLocation;
    
    if (widget.initialLocation == null) {
      _geofenceBloc.add(GeofenceLoadChildLocation(widget.childId));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _geofenceBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: BlocListener<GeofenceBloc, GeofenceState>(
          bloc: _geofenceBloc,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            
            if (state.createdZone != null) {
              Navigator.of(context).pop(true);
            }

            if (state.childLocation != null && _selectedLocation == null) {
              setState(() {
                _selectedLocation = LatLng(
                  state.childLocation!.latitude,
                  state.childLocation!.longitude,
                );
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_location_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create Safe Zone',
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Map section
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _selectedLocation != null
                      ? GoogleMap(
                          onMapCreated: (controller) => _mapController = controller,
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation!,
                            zoom: 16.0,
                          ),
                          onTap: (LatLng location) {
                            setState(() {
                              _selectedLocation = location;
                            });
                          },
                          markers: _selectedLocation != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId('zone_center'),
                                    position: _selectedLocation!,
                                    draggable: true,
                                    onDragEnd: (LatLng newLocation) {
                                      setState(() {
                                        _selectedLocation = newLocation;
                                      });
                                    },
                                  ),
                                }
                              : {},
                          circles: _selectedLocation != null
                              ? {
                                  Circle(
                                    circleId: const CircleId('geofence_preview'),
                                    center: _selectedLocation!,
                                    radius: _radius,
                                    fillColor: _parseColor(_selectedColor)
                                        .withOpacity(0.2),
                                    strokeColor: _parseColor(_selectedColor),
                                    strokeWidth: 2,
                                  ),
                                }
                              : {},
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
              ),

              // Form section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Zone name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Zone Name',
                            hintText: 'e.g., Home, School, Park',
                            prefixIcon: const Icon(Icons.label),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a zone name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Radius slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Radius: ${_radius.round()} meters',
                              style: AppTextStyles.bodyBold,
                            ),
                            Slider(
                              value: _radius,
                              min: 50,
                              max: 1000,
                              divisions: 19,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() {
                                  _radius = value;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Color selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zone Color',
                              style: AppTextStyles.bodyBold,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: _colorOptions.map((color) {
                                final isSelected = color == _selectedColor;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedColor = color;
                                    });
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: _parseColor(color),
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: AppColors.textPrimary,
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.bodyBold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BlocBuilder<GeofenceBloc, GeofenceState>(
                        bloc: _geofenceBloc,
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: state.isLoading ? null : _createGeofence,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: state.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Create Zone',
                                    style: AppTextStyles.bodyBold.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createGeofence() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location for the zone'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _geofenceBloc.add(
      GeofenceCreateRequested(
        childId: widget.childId,
        name: _nameController.text.trim(),
        centerLatitude: _selectedLocation!.latitude,
        centerLongitude: _selectedLocation!.longitude,
        radiusMeters: _radius,
        description: _descriptionController.text.trim(),
        color: _selectedColor,
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary; // fallback color
    }
  }
}
