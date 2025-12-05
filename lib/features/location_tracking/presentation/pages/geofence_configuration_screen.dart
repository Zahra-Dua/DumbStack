import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';

class GeofenceConfigurationScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentId;

  const GeofenceConfigurationScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  State<GeofenceConfigurationScreen> createState() => _GeofenceConfigurationScreenState();
}

class _GeofenceConfigurationScreenState extends State<GeofenceConfigurationScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radiusInputController = TextEditingController();
  double _radius = 1000.0; // in meters
  LatLng _centerLocation = const LatLng(33.6844, 73.0479); // Islamabad
  Set<Circle> _geofenceCircles = {};
  bool _isLoading = false;
  bool _isEditingRadius = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = '${widget.childName}\'s Safe Zone';
    _updateGeofenceCircle();
  }

  void _updateGeofenceCircle() {
    setState(() {
      _geofenceCircles = {
        Circle(
          circleId: const CircleId('geofence'),
          center: _centerLocation,
          radius: _radius,
          fillColor: AppColors.darkCyan.withOpacity(0.2),
          strokeColor: AppColors.darkCyan,
          strokeWidth: 2,
        ),
      };
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _centerLocation = position;
    });
    _updateGeofenceCircle();
  }

  void _onRadiusChanged(double value) {
    // Round to nearest 10 meters
    final roundedValue = (value / 10).round() * 10.0;
    setState(() {
      _radius = roundedValue.clamp(0.0, 5000.0);
    });
    _updateGeofenceCircle();
  }

  void _onRadiusTextDoubleTap() {
    setState(() {
      _isEditingRadius = true;
      _radiusInputController.text = _radius.toInt().toString();
    });
  }

  void _saveManualRadius() {
    final inputValue = int.tryParse(_radiusInputController.text);
    if (inputValue != null && inputValue >= 0 && inputValue <= 5000) {
      // Round to nearest 10 meters
      final roundedValue = (inputValue / 10).round() * 10.0;
      setState(() {
        _radius = roundedValue.clamp(0.0, 5000.0);
        _isEditingRadius = false;
      });
      _updateGeofenceCircle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number between 0 and 5000'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelManualRadius() {
    setState(() {
      _isEditingRadius = false;
      _radiusInputController.clear();
    });
  }

  Future<void> _saveGeofence() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save geofence to Firebase in location subcollection
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('parents')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('location')
          .doc('geofences')
          .collection('zones')
          .doc();

      await docRef.set({
        'childId': widget.childId,
        'name': _nameController.text.trim(),
        'centerLatitude': _centerLocation.latitude,
        'centerLongitude': _centerLocation.longitude,
        'radiusMeters': _radius,
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'description': null,
        'color': '#4A90E2',
      });

      print('✅ Geofence saved to: parents/${widget.parentId}/children/${widget.childId}/location/geofences/zones/${docRef.id}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geofence saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error saving geofence: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving geofence: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        title: Text('${widget.childName}\'s Geofence'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Column(
        children: [
          // Name Input
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
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter geofence name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.darkCyan),
                ),
              ),
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
                  },
                  onTap: _onMapTap,
                  initialCameraPosition: CameraPosition(
                    target: _centerLocation,
                    zoom: 15.0,
                  ),
                  circles: _geofenceCircles,
                  markers: {
                    Marker(
                      markerId: const MarkerId('center'),
                      position: _centerLocation,
                      infoWindow: const InfoWindow(
                        title: 'Geofence Center',
                        snippet: 'Tap to move center',
                      ),
                    ),
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),

          // Radius Slider
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Radius',
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (!_isEditingRadius)
                      GestureDetector(
                        onDoubleTap: _onRadiusTextDoubleTap,
                        child: Text(
                          '${_radius.toInt()} m',
                          style: TextStyle(
                            fontSize: mq.sp(0.05),
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCyan,
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _radiusInputController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: mq.sp(0.05),
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkCyan,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.darkCyan),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.darkCyan, width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _saveManualRadius(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'm',
                            style: TextStyle(
                              fontSize: mq.sp(0.05),
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkCyan,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check, size: 20),
                            color: Colors.green,
                            onPressed: _saveManualRadius,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.red,
                            onPressed: _cancelManualRadius,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!_isEditingRadius) ...[
                  SizedBox(height: mq.h(0.02)),
                  Slider(
                    value: _radius,
                    min: 0.0,
                    max: 5000.0,
                    divisions: 500, // 5000 / 10 = 500 divisions (10m steps)
                    activeColor: AppColors.darkCyan,
                    inactiveColor: AppColors.darkCyan.withOpacity(0.3),
                    onChanged: _onRadiusChanged,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0m',
                        style: TextStyle(
                          fontSize: mq.sp(0.035),
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        '5000m',
                        style: TextStyle(
                          fontSize: mq.sp(0.035),
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.only(top: mq.h(0.01)),
                    child: Text(
                      'Double tap on radius value to edit manually',
                      style: TextStyle(
                        fontSize: mq.sp(0.03),
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Save Button
          Container(
            margin: EdgeInsets.fromLTRB(
              mq.w(0.04),
              0,
              mq.w(0.04),
              mq.h(0.02),
            ),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveGeofence,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCyan,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: mq.h(0.02)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Save',
                      style: TextStyle(
                        fontSize: mq.sp(0.05),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusInputController.dispose();
    super.dispose();
  }
}
