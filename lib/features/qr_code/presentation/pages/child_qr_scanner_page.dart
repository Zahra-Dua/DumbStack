import 'package:flutter/material.dart';
import '../../../user_management/data/models/parent_model.dart';
import '../../../user_management/data/models/child_model.dart';
import '../../../user_management/data/datasources/firebase_parent_service.dart';
import '../../../../core/widgets/qr_scanner_widget.dart';

class ChildQRScannerPage extends StatefulWidget {
  final ParentModel parent;

  const ChildQRScannerPage({
    super.key,
    required this.parent,
  });

  @override
  State<ChildQRScannerPage> createState() => _ChildQRScannerPageState();
}

class _ChildQRScannerPageState extends State<ChildQRScannerPage> {
  final FirebaseParentService _firebaseService = FirebaseParentService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Parent QR Code'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: QRScannerWidget(
        title: 'Scan Parent QR Code',
        subtitle: 'Point your camera at the parent\'s QR code to join their family',
        onQRCodeDetected: _handleQRCodeDetected,
      ),
    );
  }

  Future<void> _handleQRCodeDetected(Map<String, dynamic> qrData) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      print('QR Data received: $qrData');
      
      // Handle different QR code types
      String? parentId;
      
      if (qrData['type'] == 'user_profile') {
        // Parent profile QR code
        if (qrData['userType'] == 'parent') {
          parentId = qrData['uid'];
        }
      } else if (qrData['type'] == 'firebase_id') {
        // Simple Firebase ID - try to get parent data
        parentId = qrData['id'];
      } else if (qrData['type'] == 'family_invite') {
        // Family invite QR code
        parentId = qrData['familyId'];
      }

      if (parentId == null) {
        _showError('Invalid QR code. Please scan a valid parent QR code.');
        return;
      }

      // Check if parent exists
      final parent = await _firebaseService.getParent(parentId);
      if (parent == null) {
        _showError('Parent not found. Please make sure the QR code is valid.');
        return;
      }

      // Check if child is already added to this parent
      final existingChildren = await _firebaseService.getChildren(parentId);
      final isAlreadyAdded = existingChildren.any((child) => 
        child.email == widget.parent.email || 
        child.childId == widget.parent.parentId
      );

      if (isAlreadyAdded) {
        _showError('You are already added to this parent\'s family.');
        return;
      }

      // Create child data for this parent
      final childData = ChildModel(
        childId: widget.parent.parentId, // Using parent's ID as child ID for demo
        parentId: parentId,
        name: widget.parent.name,
        email: widget.parent.email,
        userType: 'child',
        avatarUrl: '', // Child can have avatar URL for image uploads
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isLocationTrackingEnabled: true,
        currentLocationStatus: 'unknown',
      );

      // Add child to parent's subcollection
      await _firebaseService.addChild(parentId, childData);

      // Show success message
      _showSuccess('Successfully joined ${parent.name}\'s family!');
      
      // Navigate back after delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });

    } catch (e) {
      print('Error processing QR code: $e');
      _showError('Error processing QR code: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
