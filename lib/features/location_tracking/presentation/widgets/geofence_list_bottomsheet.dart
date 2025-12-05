import 'package:flutter/material.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';

class GeofenceListBottomSheet extends StatelessWidget {
  final List<GeofenceZone> zones;
  const GeofenceListBottomSheet({super.key, required this.zones});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Safe Zones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...zones.map((z) => ListTile(
                title: Text(z.name),
                subtitle: Text('Radius ${z.radiusMeters.toStringAsFixed(0)} m'),
                leading: const Icon(Icons.shield, color: AppColors.darkCyan),
              )),
        ],
      ),
    );
  }
}