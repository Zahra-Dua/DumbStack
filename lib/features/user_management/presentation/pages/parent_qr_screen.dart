import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/core/utils/error_message_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ParentQRScreen extends StatefulWidget {
  const ParentQRScreen({super.key});

  @override
  State<ParentQRScreen> createState() => _ParentQRScreenState();
}

class _ParentQRScreenState extends State<ParentQRScreen> {
  String? _qrData;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<QuerySnapshot>? _childrenStream;
  int _initialChildrenCount = 0;
  DateTime? _qrCodeGeneratedAt;
  Timer? _expirationTimer;
  Timer? _updateTimer; // Timer to update UI every second
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _checkQRCodeExpiration().then((_) {
      if (!_isExpired) {
        // If not expired, check if we have existing QR data
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          setState(() {
            _qrData = currentUser.uid;
            _isLoading = false;
          });
          // Make sure timer starts if QR code exists
          if (_qrCodeGeneratedAt != null) {
            _startExpirationTimer();
            _startUpdateTimer();
          }
        }
      } else {
        // If expired, generate new one
        _generateQRCode();
      }
    });
    _setupChildListener();
  }

  @override
  void dispose() {
    _childrenStream?.cancel();
    _expirationTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _isExpired = false;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Use parent UID directly as QR data
      final parentUid = currentUser.uid;
      final now = DateTime.now();
      
      print('🔍 [ParentQR] Using parent UID as QR data: $parentUid');
      print('🔍 [ParentQR] QR data length: ${parentUid.length}');
      print('🔍 [ParentQR] QR code generated at: $now');

      // Store QR code generation timestamp in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentUid)
            .update({
          'qrCodeGeneratedAt': FieldValue.serverTimestamp(),
          'qrCodeExpiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 5))),
        });
      } catch (e) {
        print('⚠️ [ParentQR] Error storing QR timestamp: $e');
        // Continue even if Firestore update fails
      }

      // Cancel previous timer if exists
      _expirationTimer?.cancel();

      setState(() {
        _qrData = parentUid; // Use parentUid as QR content
        _qrCodeGeneratedAt = now;
        _isLoading = false;
      });
      
      print('🔍 [ParentQR] State updated - _qrData: $_qrData');

      // Start expiration timer (5 minutes)
      _startExpirationTimer();
      // Start UI update timer (updates every second)
      _startUpdateTimer();

      // Show success message after state is updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code generated! Share it with your child. This code will expire in 5 minutes.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      print('❌ [ParentQR] Error generating QR code: $e');
      setState(() {
        if (ErrorMessageHelper.isNetworkError(e)) {
          _error = ErrorMessageHelper.networkErrorQRGeneration;
        } else {
          _error = 'Error generating QR code: ${e.toString()}';
        }
        _isLoading = false;
      });
    }
  }

  void _startExpirationTimer() {
    if (_qrCodeGeneratedAt == null) return;

    final expirationTime = _qrCodeGeneratedAt!.add(const Duration(minutes: 5));
    final now = DateTime.now();
    final durationUntilExpiration = expirationTime.difference(now);

    if (durationUntilExpiration.isNegative) {
      // Already expired
      setState(() {
        _isExpired = true;
      });
      _updateTimer?.cancel();
      return;
    }

    // Set timer to check expiration
    _expirationTimer = Timer(durationUntilExpiration, () {
      if (mounted) {
        setState(() {
          _isExpired = true;
        });
        _updateTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code has expired. Please generate a new one.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isExpired) {
        timer.cancel();
        return;
      }
      // Update UI every second to show countdown
      setState(() {
        // Just trigger rebuild to update timer display
      });
    });
  }

  Future<void> _checkQRCodeExpiration() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final expiresAt = data['qrCodeExpiresAt'] as Timestamp?;
        
        if (expiresAt != null) {
          final expirationTime = expiresAt.toDate();
          final now = DateTime.now();
          
          if (now.isAfter(expirationTime)) {
            setState(() {
              _isExpired = true;
            });
          } else {
            // Update local timestamp and restart timer
            final generatedAt = data['qrCodeGeneratedAt'] as Timestamp?;
            if (generatedAt != null) {
              setState(() {
                _qrCodeGeneratedAt = generatedAt.toDate();
                _isExpired = false;
              });
              _startExpirationTimer();
              _startUpdateTimer();
            } else {
              // If no timestamp exists, set current time (for new QR codes)
              setState(() {
                _qrCodeGeneratedAt = DateTime.now();
                _isExpired = false;
              });
              _startExpirationTimer();
              _startUpdateTimer();
            }
          }
        } else {
          // No expiration set, but QR data exists - set default expiration
          setState(() {
            _qrCodeGeneratedAt = DateTime.now();
            _isExpired = false;
          });
          _startExpirationTimer();
          _startUpdateTimer();
        }
      }
    } catch (e) {
      print('⚠️ [ParentQR] Error checking expiration: $e');
    }
  }

  void _setupChildListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Get initial children count
      FirebaseFirestore.instance
          .collection('parents')
          .doc(currentUser.uid)
          .collection('children')
          .get()
          .then((snapshot) {
        _initialChildrenCount = snapshot.docs.length;
      });

      // Listen for changes in children collection
      _childrenStream = FirebaseFirestore.instance
          .collection('parents')
          .doc(currentUser.uid)
          .collection('children')
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        print('🔄 [ParentQR] Children count changed: ${snapshot.docs.length}');
        
        // If a new child was added, show success message but DON'T auto-navigate
        if (snapshot.docs.length > _initialChildrenCount) {
          _initialChildrenCount = snapshot.docs.length;
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.child_care, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Child successfully linked! You can now go back to home.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Don't auto-navigate - let parent decide when to go back
        }
      });
    }
  }

  String _getTimeUntilExpiration() {
    if (_qrCodeGeneratedAt == null) {
      // If no timestamp, assume 5 minutes from now
      return '5:00';
    }
    
    final expirationTime = _qrCodeGeneratedAt!.add(const Duration(minutes: 5));
    final now = DateTime.now();
    final difference = expirationTime.difference(now);
    
    if (difference.isNegative || difference.inSeconds <= 0) {
      return 'Expired';
    }
    
    final totalSeconds = difference.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    
    print('🔍 [ParentQR] Build called - _isLoading: $_isLoading, _error: $_error, _qrData: $_qrData');
    
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text('Your QR Code'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mq.w(0.06)),
          child: Column(
            children: [
              Text(
                'Share Your QR Code',
                style: TextStyle(
                  fontSize: mq.sp(0.06),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: mq.h(0.02)),
              Text(
                'Let your child scan this QR code to join your family',
                style: TextStyle(fontSize: mq.sp(0.04)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: mq.h(0.04)),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      SizedBox(height: mq.h(0.02)),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: mq.sp(0.04)),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: mq.h(0.02)),
                      ElevatedButton(
                        onPressed: _generateQRCode,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_isExpired)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 64,
                        color: Colors.orange[400],
                      ),
                      SizedBox(height: mq.h(0.02)),
                      Text(
                        'QR Code Expired',
                        style: TextStyle(
                          fontSize: mq.sp(0.05),
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      SizedBox(height: mq.h(0.01)),
                      Text(
                        'This QR code has expired. Please generate a new one.',
                        style: TextStyle(fontSize: mq.sp(0.04)),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: mq.h(0.03)),
                      ElevatedButton.icon(
                        onPressed: _generateQRCode,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Generate New QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkCyan,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: mq.w(0.06),
                            vertical: mq.h(0.02),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_qrData != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Always show timer if QR data exists
                    Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: mq.w(0.04),
                          vertical: mq.h(0.01),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Expires in ${_getTimeUntilExpiration()}',
                          style: TextStyle(
                            fontSize: mq.sp(0.032),
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(height: mq.h(0.02)),
                    Text(
                      'QR Data: $_qrData',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: mq.h(0.02)),
                    Container(
                      padding: EdgeInsets.all(mq.w(0.04)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 200.0, // Fixed size instead of responsive
                        backgroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: mq.h(0.04)),
                    Text(
                      'Parent ID: ${FirebaseAuth.instance.currentUser?.uid.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: mq.sp(0.035),
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: mq.h(0.03)),
                    Container(
                      padding: EdgeInsets.all(mq.w(0.03)),
                      decoration: BoxDecoration(
                        color: AppColors.darkCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.darkCyan.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.darkCyan,
                            size: 24,
                          ),
                          SizedBox(height: mq.h(0.01)),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: mq.sp(0.04),
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkCyan,
                            ),
                          ),
                          SizedBox(height: mq.h(0.01)),
                          Text(
                            '1. Open SafeNest on child\'s device\n'
                            '2. Select "Child" account type\n'
                            '3. Scan this QR code\n'
                            '4. Enter child\'s name when prompted',
                            style: TextStyle(fontSize: mq.sp(0.032)),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              
              SizedBox(height: mq.h(0.03)),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isExpired || _qrData == null ? _generateQRCode : _generateQRCode,
                    icon: const Icon(Icons.refresh),
                    label: Text(_isExpired ? 'Generate New QR Code' : 'Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isExpired ? AppColors.darkCyan : null,
                      foregroundColor: _isExpired ? Colors.white : null,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate back to home screen
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Back to Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add functionality to share QR code
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share functionality coming soon')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
              SizedBox(height: mq.h(0.02)), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }
}
