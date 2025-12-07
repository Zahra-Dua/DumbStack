import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';

class GeofenceSettingsCard extends StatefulWidget {
  final String childId;
  final String childName;
  final VoidCallback? onTap;

  const GeofenceSettingsCard({
    super.key,
    required this.childId,
    required this.childName,
    this.onTap,
  });

  @override
  State<GeofenceSettingsCard> createState() => _GeofenceSettingsCardState();
}

class _GeofenceSettingsCardState extends State<GeofenceSettingsCard> {
  bool _isGeofenceEnabled = false;
  double _radius = 100.0; // in meters
  String _zoneName = '';

  @override
  void initState() {
    super.initState();
    _zoneName = '${widget.childName}\'s Safe Zone';
    _loadGeofenceSettings();
  }

  Future<void> _loadGeofenceSettings() async {
    // TODO: Load geofence settings from Firebase
    // For now, using default values
    setState(() {
      _isGeofenceEnabled = false;
      _radius = 100.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.darkCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_searching,
                      color: AppColors.darkCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Geofence Zone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set safe zones for ${widget.childName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isGeofenceEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isGeofenceEnabled = value;
                      });
                      _saveGeofenceSettings();
                    },
                    activeColor: AppColors.darkCyan,
                  ),
                ],
              ),
              
              if (_isGeofenceEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Geofence is active',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zone: $_zoneName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                      Text(
                        'Radius: ${_radius.toInt()} meters',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.darkCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to configure zones',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkCyan,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGeofenceSettings() async {
    // TODO: Save geofence settings to Firebase
    print('Geofence settings saved: enabled=$_isGeofenceEnabled, radius=$_radius');
  }
}
