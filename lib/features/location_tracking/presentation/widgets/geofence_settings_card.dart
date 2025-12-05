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
    final mq = MQ(context);

    return Card(
      margin: EdgeInsets.all(mq.w(0.04)),
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(mq.w(0.04)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(mq.w(0.03)),
                    decoration: BoxDecoration(
                      color: AppColors.darkCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_searching,
                      color: AppColors.darkCyan,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: mq.w(0.03)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geofence Zone',
                          style: TextStyle(
                            fontSize: mq.sp(0.05),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Set safe zones for ${widget.childName}',
                          style: TextStyle(
                            fontSize: mq.sp(0.04),
                            color: AppColors.textLight,
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
              
              SizedBox(height: mq.h(0.02)),
              
              if (_isGeofenceEnabled) ...[
                Container(
                  padding: EdgeInsets.all(mq.w(0.03)),
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
                          Icon(
                            Icons.info_outline,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: mq.w(0.02)),
                          Expanded(
                            child: Text(
                              'Geofence is active',
                              style: TextStyle(
                                fontSize: mq.sp(0.04),
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: mq.h(0.01)),
                      Text(
                        'Zone: $_zoneName',
                        style: TextStyle(
                          fontSize: mq.sp(0.035),
                          color: Colors.green[600],
                        ),
                      ),
                      Text(
                        'Radius: ${_radius.toInt()} meters',
                        style: TextStyle(
                          fontSize: mq.sp(0.035),
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: mq.h(0.02)),
              ],
              
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.darkCyan,
                    size: 16,
                  ),
                  SizedBox(width: mq.w(0.01)),
                  Text(
                    'Tap to configure zones',
                    style: TextStyle(
                      fontSize: mq.sp(0.04),
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
