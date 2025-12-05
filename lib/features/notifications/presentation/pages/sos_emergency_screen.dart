import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/alert_sender_service.dart';

/// SOS Emergency Screen for Child App
class SOSEmergencyScreen extends StatefulWidget {
  const SOSEmergencyScreen({super.key});

  @override
  State<SOSEmergencyScreen> createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen> {
  final AlertSenderService _alertSenderService = AlertSenderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSending = false;

  /// Get parent ID from Firebase by finding which parent has this child
  Future<String?> _getParentId(String childId) async {
    try {
      // Search through all parents to find which one has this child
      final parentsQuery = await _firestore.collection('parents').get();
      
      for (final parentDoc in parentsQuery.docs) {
        final childDoc = await _firestore
            .collection('parents')
            .doc(parentDoc.id)
            .collection('children')
            .doc(childId)
            .get();
        
        if (childDoc.exists) {
          return parentDoc.id;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting parent ID: $e');
      return null;
    }
  }

  Future<void> _triggerSOS() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Get child ID from Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showError('User not logged in');
        setState(() { _isSending = false; });
        return;
      }

      final childId = currentUser.uid;
      
      // Get parent ID from Firebase
      final parentId = await _getParentId(childId);

      if (parentId == null) {
        _showError('Parent not found. Please ensure you are linked to a parent account.');
        setState(() { _isSending = false; });
        return;
      }

      // Get current location
      Position? position;
      String? address;
      
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        print('✅ SOS: Location obtained - ${position.latitude}, ${position.longitude}');
        
        // Geocode address from coordinates
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks[0];
            address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
            address = address.replaceAll(RegExp(r',\s*,'), ',').trim();
            if (address.startsWith(',')) address = address.substring(1).trim();
            print('✅ SOS: Address geocoded - $address');
          }
        } catch (e) {
          print('⚠️ SOS: Error geocoding address: $e');
          address = 'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        print('⚠️ SOS: Error getting location: $e');
        _showError('Could not get location. SOS alert will be sent without location.');
        // Continue with SOS even if location fails
      }

      // Send SOS alert with location
      await _alertSenderService.sendSOSAlert(
        parentId: parentId,
        childId: childId,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        address: address,
      );
      
      print('✅ SOS: Alert sent to parent with location');

      _showSuccess('SOS alert sent to parent!');
    } catch (e) {
      _showError('Error sending SOS: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Emergency'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emergency,
                size: 120,
                color: Colors.red,
              ),
              const SizedBox(height: 32),
              const Text(
                'Emergency SOS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Press the button below to send an emergency alert to your parent',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSending ? null : _triggerSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'SEND SOS ALERT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

