import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/core/utils/error_message_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parental_control_app/core/di/service_locator.dart';
import 'package:parental_control_app/features/user_management/domain/usecases/link_child_to_parent_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parental_control_app/features/user_management/presentation/pages/child_permissions_screen.dart';
import 'package:parental_control_app/core/services/qr_code_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parental_control_app/features/location_tracking/data/services/child_location_service.dart';
import 'package:parental_control_app/features/location_tracking/data/datasources/location_remote_datasource.dart';
import 'package:parental_control_app/features/location_tracking/data/datasources/geofence_remote_datasource.dart';
import 'package:parental_control_app/features/location_tracking/data/services/geofencing_detection_service.dart';
import 'package:parental_control_app/features/location_tracking/data/models/geofence_zone_model.dart';
import 'package:parental_control_app/features/location_tracking/data/models/zone_event_model.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/zone_event_entity.dart';
import 'package:intl/intl.dart';
// import 'package:parental_control_app/features/messaging/data/services/workmanager_message_service.dart';
import 'package:parental_control_app/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:parental_control_app/features/call_logging/data/datasources/call_log_remote_datasource.dart';
import 'package:parental_control_app/features/notifications/presentation/pages/sos_emergency_screen.dart';
import 'package:parental_control_app/features/child_tracking/data/services/real_data_collection_service.dart';
import 'package:parental_control_app/features/app_limits/presentation/pages/child_installed_apps_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChildScanQRScreen extends StatefulWidget {
  const ChildScanQRScreen({super.key});

  @override
  State<ChildScanQRScreen> createState() => _ChildScanQRScreenState();
}

class _ChildScanQRScreenState extends State<ChildScanQRScreen> {
  bool _scanning = true;
  bool _isCheckingLink = true;
  bool _isProcessingQR = false; // Prevent multiple QR processing
  MobileScannerController cameraController = MobileScannerController();
  Timer? _expirationCheckTimer; // Timer to check expiration periodically
  String? _currentParentUid; // Store scanned parent UID
  DateTime? _qrExpiresAt; // Store expiration time
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  final List<String> _selectedHobbies = [];
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<String> _availableHobbies = [
    'Reading', 'Sports', 'Music', 'Art', 'Gaming', 
    'Cooking', 'Dancing', 'Swimming', 'Cycling', 'Photography'
  ];

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLinked();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    cameraController.dispose();
    _expirationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkIfAlreadyLinked() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Check if this child is already linked by looking for their UID in any parent's childrenIds
        // This is a simplified check - in a real app, you'd want to store the parentId in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final parentUid = prefs.getString('parent_uid');
        
        if (parentUid != null) {
          // Child is already linked, check permissions first
          print('✅ CHILD ALREADY LINKED: Parent ID found: $parentUid');
          print('🔐 CHECKING PERMISSIONS: Verifying message permissions...');
          
          // Check if message permissions are granted
          final smsGranted = await Permission.sms.isGranted;
          final phoneGranted = await Permission.phone.isGranted;
          
          if (smsGranted && phoneGranted) {
            print('✅ PERMISSIONS GRANTED: Going to home screen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChildHomeScreen()),
            );
          } else {
            print('⚠️ PERMISSIONS MISSING: Going to permissions screen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChildPermissionsScreen()),
            );
          }
          return;
        }
      }
    } catch (e) {
      // If there's an error checking, continue with normal flow
    }
    
    setState(() {
      _isCheckingLink = false;
    });
    _handlePermissions();
  }

  Future<void> _handlePermissions() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text('Please enable camera permission in app settings to scan QR codes.'),
          actions: [
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _linkChildToParent(String parentUid) async {
    final childData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildChildProfileDialog(),
    );

    if (childData == null) {
      setState(() { 
        _scanning = true;
        _isProcessingQR = false;
      });
      return;
    }

    try {
      final usecase = sl<LinkChildToParentUseCase>();
      await usecase(
        parentUid: parentUid,
        firstName: childData['firstName'] ?? '',
        lastName: childData['lastName'] ?? '',
        childName: childData['name'],
        age: childData['age'],
        gender: childData['gender'],
        hobbies: childData['hobbies'],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', 'child');
      await prefs.setString('child_name', childData['name']);
      await prefs.setString('parent_uid', parentUid);
      await prefs.setString('child_uid', FirebaseAuth.instance.currentUser!.uid);
      print('Stored parent_uid: $parentUid, child_uid: ${FirebaseAuth.instance.currentUser!.uid}');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully linked to parent! Welcome ${childData['name']}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navigate to permissions screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChildPermissionsScreen()),
      );
    } catch (e) {
      print('Error linking to parent: $e');
      String errorMessage;
      if (ErrorMessageHelper.isNetworkError(e)) {
        errorMessage = ErrorMessageHelper.networkErrorLinking;
      } else if (e.toString().contains('Cannot add more than 5 children')) {
        errorMessage = 'Cannot add children more than 5';
        // Show dialog for child limit
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Child Limit Reached'),
            content: const Text('Cannot add children more than 5. Maximum limit reached.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        errorMessage = 'Error linking to parent: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      setState(() { 
        _scanning = true;
        _isProcessingQR = false;
      });
    }
  }

  Widget _buildChildProfileDialog() {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Let\'s setup SafeNest for your Child'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Upload Photo
                GestureDetector(
                  onTap: () async {
                    final ImageSource? source = await showDialog<ImageSource>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Select Image Source'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Camera'),
                              onTap: () => Navigator.pop(context, ImageSource.camera),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Gallery'),
                              onTap: () => Navigator.pop(context, ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
                    );
                    
                    if (source != null) {
                      final XFile? image = await _imagePicker.pickImage(source: source);
                      if (image != null) {
                        setDialogState(() {
                          _selectedImage = File(image.path);
                        });
                      }
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Tap to Upload Photo', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                
                // First Name Field
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                
                // Last Name Field
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                
                // Age Field
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Hobbies Section
                const Text('Hobbies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableHobbies.map((hobby) {
                    final isSelected = _selectedHobbies.contains(hobby);
                    return FilterChip(
                      label: Text(hobby),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            _selectedHobbies.add(hobby);
                          } else {
                            _selectedHobbies.remove(hobby);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final firstName = _firstNameController.text.trim();
                final lastName = _lastNameController.text.trim();
                
                if (firstName.isEmpty ||
                    lastName.isEmpty ||
                    _ageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }
                
                // Validate first name and last name
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(firstName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('First name must contain only alphabetic characters')),
                  );
                  return;
                }
                
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(lastName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Last name must contain only alphabetic characters')),
                  );
                  return;
                }
                
                if (firstName.length > 50 || lastName.length > 50) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name must not exceed 50 characters')),
                  );
                  return;
                }
                
                final age = int.tryParse(_ageController.text.trim());
                if (age == null || age < 3 || age > 18) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid age (3-18)')),
                  );
                  return;
                }
                
                final fullName = '$firstName $lastName'.trim();
                
                Navigator.pop(context, {
                  'firstName': firstName,
                  'lastName': lastName,
                  'name': fullName,
                  'age': age,
                  'gender': _selectedGender,
                  'hobbies': List<String>.from(_selectedHobbies),
                });
              },
              child: const Text('Connect to parent'),
            ),
          ],
        );
      },
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_scanning || _isProcessingQR) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;

    // Prevent multiple processing
    setState(() { 
      _scanning = false;
      _isProcessingQR = true;
    });
    
    try {
      print('Scanned QR data: $raw'); // Debug log
      
      // Use QRCodeService to parse the data (handles both JSON and plain string)
      Map<String, dynamic>? qrData = QRCodeService.jsonToData(raw);
      print('QR parsing result: $qrData'); // Debug log
      
      String? parentUid;
      
      // Check if QR data is JSON format
      // Handle different QR code types (JSON format)
      if (qrData != null) {
        if (qrData['type'] == 'user_profile') {
          // Parent profile QR code
          if (qrData['userType'] == 'parent') {
            parentUid = qrData['uid'];
          }
        } else if (qrData['type'] == 'firebase_id') {
          // Simple Firebase ID
          parentUid = qrData['id'];
        } else if (qrData['type'] == 'family_invite') {
          // Family invite QR code
          parentUid = qrData['familyId'];
        }
      } else {
        // If JSON parsing failed, check if it's a plain Firebase UID
        // Firebase UIDs are typically 28 characters, alphanumeric with some special chars
        if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(raw.trim())) {
          print('Detected plain Firebase UID format: $raw');
          // Treat as direct Firebase parent UID
          parentUid = raw.trim();
        }
      }
              
      if (parentUid == null || parentUid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR code format. Please scan a valid parent QR code.')),
        );
        setState(() { 
          _scanning = true;
          _isProcessingQR = false;
        });
        return;
      }
      
      print('Extracted parent UID: $parentUid'); // Debug log
      
      // Check if QR code has expired
      try {
        final parentDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentUid)
            .get();
        
        if (!parentDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parent account not found. Please check the QR code.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { 
            _scanning = true;
            _isProcessingQR = false;
          });
          return;
        }
        
        final data = parentDoc.data();
        if (data != null) {
          final expiresAt = data['qrCodeExpiresAt'] as Timestamp?;
          
          if (expiresAt != null) {
            final expirationTime = expiresAt.toDate();
            final now = DateTime.now();
            
            // Add 30 second buffer to account for clock differences and network delays
            // Check if current time is after expiration (with buffer)
            final timeUntilExpiration = expirationTime.difference(now);
            
            if (timeUntilExpiration.inSeconds < -30) {
              // QR code has expired
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(ErrorMessageHelper.expiredLinkingCode),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
              setState(() { 
                _scanning = true;
                _isProcessingQR = false;
                _currentParentUid = null;
                _qrExpiresAt = null;
              });
              _expirationCheckTimer?.cancel();
              return;
            } else {
              // QR code is still valid - store expiration info for timer display
              setState(() {
                _currentParentUid = parentUid;
                _qrExpiresAt = expirationTime;
              });
              _startExpirationCheckTimer(expirationTime);
              // Continue with linking - don't return here
            }
          } else {
            // No expiration set, allow linking
            setState(() {
              _currentParentUid = parentUid;
              _qrExpiresAt = null;
            });
          }
          
          // Continue with linking process
          await _linkChildToParent(parentUid);
        }
      } catch (e) {
        print('Error checking QR expiration: $e');
        // If error checking expiration, continue with linking (graceful degradation)
        if (ErrorMessageHelper.isNetworkError(e)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(ErrorMessageHelper.networkErrorLinking),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { 
            _scanning = true;
            _isProcessingQR = false;
          });
          return;
        }
      }
      
      await _linkChildToParent(parentUid);
      // Clear timer after successful link
      _expirationCheckTimer?.cancel();
      setState(() {
        _currentParentUid = null;
        _qrExpiresAt = null;
      });
      } catch (e) {
      print('Error scanning QR: $e'); // Debug log
      String errorMessage;
      if (ErrorMessageHelper.isNetworkError(e)) {
        errorMessage = ErrorMessageHelper.networkErrorLinking;
      } else {
        errorMessage = 'Error scanning QR: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      setState(() { 
        _scanning = true;
        _isProcessingQR = false;
        _currentParentUid = null;
        _qrExpiresAt = null;
      });
      _expirationCheckTimer?.cancel();
    } finally {
      // Always reset processing flag
      _isProcessingQR = false;
    }
  }

  void _startExpirationCheckTimer(DateTime expirationTime) {
    _expirationCheckTimer?.cancel();
    _expirationCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      if (now.isAfter(expirationTime.add(const Duration(seconds: 10)))) {
        // Expired
        timer.cancel();
        setState(() {
          _currentParentUid = null;
          _qrExpiresAt = null;
        });
      } else {
        // Update UI to show remaining time
        setState(() {});
      }
    });
  }

  String _getTimeUntilExpiration() {
    if (_qrExpiresAt == null) return '';
    
    final now = DateTime.now();
    final difference = _qrExpiresAt!.difference(now);
    
    if (difference.isNegative) return 'Expired';
    
    final totalSeconds = difference.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    
    if (_isCheckingLink) {
      return Scaffold(
        backgroundColor: AppColors.lightCyan,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Parent QR Code'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),
          ),
          Container(
            padding: EdgeInsets.all(mq.w(0.04)),
            color: AppColors.lightCyan,
            child: Column(
              children: [
                if (_qrExpiresAt != null && _currentParentUid != null)
                  Container(
                    margin: EdgeInsets.only(bottom: mq.h(0.02)),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                        SizedBox(width: mq.w(0.02)),
                        Text(
                          'QR Code expires in: ${_getTimeUntilExpiration()}',
                          style: TextStyle(
                            fontSize: mq.sp(0.032),
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Scan your parent\'s QR code to join the family',
                  style: TextStyle(
                    fontSize: mq.sp(0.04),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: mq.h(0.02)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => cameraController.toggleTorch(),
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Flash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCyan,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => cameraController.switchCamera(),
                      icon: const Icon(Icons.flip_camera_ios),
                      label: const Text('Switch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCyan,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Refresh/clear current scan state
                        setState(() {
                          _currentParentUid = null;
                          _qrExpiresAt = null;
                          _scanning = true;
                          _isProcessingQR = false;
                        });
                        _expirationCheckTimer?.cancel();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ready to scan new QR code'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  bool _isLocationTracking = false;
  bool _isGeofencingMonitoring = false;
  late ChildLocationService _locationService;
  GeofencingDetectionService? _geofencingService;
  final RealDataCollectionService _dataCollectionService = RealDataCollectionService();
  String _childName = 'Loading...';
  String _parentName = 'Loading...';
  String? _linkedParentId;
  String? _linkedChildId;
  bool _isLoadingZones = true;
  List<GeofenceZoneModel> _activeZones = [];
  ZoneEventModel? _latestZoneEvent;
  String? _latestZoneEventId;
  final Map<String, ZoneEventType> _zoneStatusById = {};
  StreamSubscription<QuerySnapshot>? _zoneEventsSubscription;
  StreamSubscription<QuerySnapshot>? _zonesSubscription;

  @override
  void initState() {
    super.initState();
    _locationService = ChildLocationService(
      locationDataSource: LocationRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
    );
    _initializeServices();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childUid = prefs.getString('child_uid');
      final parentUid = prefs.getString('parent_uid');
      
      if (childUid != null && parentUid != null) {
        String? childName;
        String? parentName;
        // Get child info
        final childDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentUid)
            .collection('children')
            .doc(childUid)
            .get();
        
        if (childDoc.exists) {
          childName = childDoc.data()?['name'] ?? 'Unknown Child';
        }
        
        // Get parent info
        final parentDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentUid)
            .get();
        
        if (parentDoc.exists) {
          parentName = parentDoc.data()?['name'] ?? 'Unknown Parent';
        }

        setState(() {
          _childName = childName ?? _childName;
          _parentName = parentName ?? _parentName;
          _linkedChildId = childUid;
          _linkedParentId = parentUid;
        });

        await _loadActiveSafeZones();
      }
    } catch (e) {
      print('❌ Error loading user info: $e');
    }
  }

  Future<void> _initializeServices() async {
    try {
      print('🚀 INITIALIZING CHILD SERVICES: Starting location and message monitoring...');
      
      // Initialize location tracking
      await _locationService.initializeLocationTracking();
      await _locationService.startLocationTracking();
      setState(() {
        _isLocationTracking = true;
      });
      
      print('✅ LOCATION TRACKING: Started successfully');
      
      // Initialize message monitoring
      await _initializeMessageMonitoring();
      
      // Initialize geofencing monitoring so child gets real-time safe zone alerts
      await _startGeofencingMonitoring();
      
      // Initialize URL and App Usage tracking for Firebase
      await _initializeDataCollection();
      
      print('✅ CHILD SERVICES: All services initialized');
    } catch (e) {
      print('❌ SERVICE INITIALIZATION ERROR: $e');
    }
  }

  Future<void> _initializeMessageMonitoring() async {
    try {
      print('🔍 INITIALIZING WORKMANAGER MESSAGE MONITORING: Starting background monitoring...');
      
      // Get parent ID from the linked parent
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return;
      }
      
      // Get parent ID from child's document in the correct location
      // First, we need to find which parent this child belongs to
      // Since we don't have parentId, we'll search through all parents
      final parentsQuery = await FirebaseFirestore.instance
          .collection('parents')
          .get();
      
      String? parentId;
      for (final parentDoc in parentsQuery.docs) {
        final childDoc = await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentDoc.id)
            .collection('children')
            .doc(currentUser.uid)
            .get();
        
        if (childDoc.exists) {
          parentId = parentDoc.id;
          break;
        }
      }
      
      if (parentId == null) {
        print('❌ Child document not found in any parent\'s children collection');
        return;
      }
      
      print('✅ Found child in parent: $parentId');
      
      // Start message monitoring (without WorkManager for now)
      final messageDataSource = MessageRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      );
      messageDataSource.startContinuousMonitoring(
        parentId: parentId,
        childId: currentUser.uid,
      );
      
      // Start call log monitoring
      final callLogDataSource = CallLogRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      );
      callLogDataSource.startContinuousMonitoring(
        parentId: parentId,
        childId: currentUser.uid,
      );
      
      print('✅ MESSAGE MONITORING: Started successfully');
      print('✅ CALL LOG MONITORING: Started successfully');
    } catch (e) {
      print('❌ WORKMANAGER MESSAGE MONITORING ERROR: $e');
    }
  }

  Future<void> _initializeDataCollection() async {
    try {
      print('🚀 INITIALIZING DATA COLLECTION: Starting URL and App Usage tracking...');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No current user found for data collection');
        return;
      }
      
      // Get parent ID from SharedPreferences or find it
      final prefs = await SharedPreferences.getInstance();
      String? parentId = prefs.getString('parent_uid');
      
      if (parentId == null || parentId.isEmpty) {
        print('❌ Parent ID not found in SharedPreferences - skipping data collection initialization');
        return;
      }
      
      print('✅ Found parent ID: $parentId');
      
      // Initialize real data collection (URL tracking + App Usage)
      await _dataCollectionService.initializeRealDataCollection(
        childId: currentUser.uid,
        parentId: parentId,
      );
      
      print('✅ DATA COLLECTION: URL and App Usage tracking initialized successfully');
      print('📊 Firebase Collections:');
      print('   - visitedUrls: parents/$parentId/children/${currentUser.uid}/visitedUrls');
      print('   - appUsage: parents/$parentId/children/${currentUser.uid}/appUsage');
    } catch (e) {
      print('❌ DATA COLLECTION ERROR: $e');
    }
  }

  Future<bool> _ensureLinkedIds() async {
    if (_linkedParentId != null && _linkedChildId != null) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final parentId = prefs.getString('parent_uid');
    final childId = prefs.getString('child_uid') ?? FirebaseAuth.instance.currentUser?.uid;

    if (parentId == null || childId == null) {
      print('❌ Unable to determine parent/child IDs for geofencing');
      return false;
    }

    setState(() {
      _linkedParentId = parentId;
      _linkedChildId = childId;
    });
    return true;
  }

  Future<void> _startGeofencingMonitoring() async {
    if (_isGeofencingMonitoring) return;

    final hasIds = await _ensureLinkedIds();
    if (!hasIds) return;

    try {
      print('🚀 Initializing geofencing detection on child device...');
      final geofenceDataSource = GeofenceRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      );

      _geofencingService = GeofencingDetectionService(
        geofenceDataSource: geofenceDataSource,
      );

      await _geofencingService!.startGeofencingMonitoring();
      setState(() {
        _isGeofencingMonitoring = true;
      });

      await _loadActiveSafeZones();
      _listenToZoneEvents();
    } catch (e) {
      print('❌ Error starting geofencing monitoring: $e');
    }
  }

  Future<void> _stopGeofencingMonitoring() async {
    await _zoneEventsSubscription?.cancel();
    _zoneEventsSubscription = null;

    try {
      await _geofencingService?.stopGeofencingMonitoring();
    } catch (e) {
      print('⚠️ Error stopping geofencing monitoring: $e');
    }

    setState(() {
      _isGeofencingMonitoring = false;
      _latestZoneEvent = null;
      _latestZoneEventId = null;
      _zoneStatusById.clear();
    });
  }

  Future<void> _loadActiveSafeZones() async {
    final hasIds = await _ensureLinkedIds();
    if (!hasIds) return;

    try {
      setState(() {
        _isLoadingZones = true;
      });

      // Cancel previous subscription
      await _zonesSubscription?.cancel();

      // Listen to zones in real-time so child sees zones immediately when parent creates them
      _zonesSubscription = FirebaseFirestore.instance
          .collection('parents')
          .doc(_linkedParentId!)
          .collection('children')
          .doc(_linkedChildId!)
          .collection('location')
          .doc('geofences')
          .collection('zones')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen(
        (snapshot) {
          final zones = snapshot.docs
              .map((doc) => GeofenceZoneModel.fromFirestore(doc.data(), doc.id))
              .toList();

          print('📍 [ChildApp] Loaded ${zones.length} active safe zones');
          setState(() {
            _activeZones = zones;
            _isLoadingZones = false;
          });
        },
        onError: (error) {
          print('❌ Error loading active safe zones: $error');
          setState(() {
            _isLoadingZones = false;
          });
        },
      );
    } catch (e) {
      print('❌ Error setting up safe zones listener: $e');
      setState(() {
        _isLoadingZones = false;
      });
    }
  }

  void _listenToZoneEvents() {
    _zoneEventsSubscription?.cancel();
    if (_linkedParentId == null || _linkedChildId == null) {
      return;
    }

    _zoneEventsSubscription = FirebaseFirestore.instance
        .collection('parents')
        .doc(_linkedParentId!)
        .collection('children')
        .doc(_linkedChildId!)
        .collection('location')
        .doc('geofences')
        .collection('zoneEvents')
        .orderBy('occurredAt', descending: true)
        .limit(25)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          return;
        }

        final latestDoc = snapshot.docs.first;
        final latestEvent = ZoneEventModel.fromFirestore(
          latestDoc.data(),
          latestDoc.id,
        );

        final isNewEvent = latestEvent.id != _latestZoneEventId;

        setState(() {
          _latestZoneEvent = latestEvent;
          _latestZoneEventId = latestEvent.id;
          _zoneStatusById[latestEvent.zoneId] = latestEvent.eventType;
        });

        if (isNewEvent && mounted) {
          _showZoneSnack(latestEvent);
        }

        for (final doc in snapshot.docs.skip(1)) {
          final event = ZoneEventModel.fromFirestore(doc.data(), doc.id);
          _zoneStatusById[event.zoneId] = event.eventType;
        }
      },
      onError: (error) => print('❌ Error listening to zone events: $error'),
    );
  }

  void _showZoneSnack(ZoneEventModel event) {
    if (!mounted) return;
    final entered = event.eventType == ZoneEventType.enter;
    final message = entered
        ? 'You entered ${event.zoneName} safe zone'
        : 'You left ${event.zoneName} safe zone';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: entered ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _zoneEventsSubscription?.cancel();
    _zonesSubscription?.cancel();
    _geofencingService?.dispose();
    _locationService.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Dashboard'),
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(mq.w(0.04)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Child and Parent Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(mq.w(0.04)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: AppColors.primary, size: 24),
                            SizedBox(width: mq.w(0.02)),
                            Text(
                              'Child: $_childName',
                              style: TextStyle(
                                fontSize: mq.sp(0.05),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: mq.h(0.01)),
                        Row(
                          children: [
                            Icon(Icons.family_restroom, color: AppColors.secondary, size: 24),
                            SizedBox(width: mq.w(0.02)),
                            Text(
                              'Parent: $_parentName',
                              style: TextStyle(
                                fontSize: mq.sp(0.04),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: mq.h(0.03)),
                
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: mq.sp(0.06),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: mq.h(0.02)),
                Text(
                  'You are now connected to your parent\'s account.',
                  style: TextStyle(
                    fontSize: mq.sp(0.04),
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: mq.h(0.04)),
                
                // Location Status Card
                Card(
                  child: ListTile(
                    leading: Icon(
                      _isLocationTracking ? Icons.location_on : Icons.location_off,
                      color: _isLocationTracking ? Colors.green : Colors.red,
                    ),
                    title: Text(_isLocationTracking ? 'Location Sharing Active' : 'Location Sharing Inactive'),
                    subtitle: Text(_isLocationTracking 
                      ? 'Your location is being shared with your parent'
                      : 'Location sharing is not active'),
                    trailing: Switch(
                      value: _isLocationTracking,
                      onChanged: (value) async {
                        if (value) {
                          await _locationService.startLocationTracking();
                        } else {
                          await _locationService.stopLocationTracking();
                        }
                        setState(() {
                          _isLocationTracking = value;
                        });
                      },
                    ),
                  ),
                ),
                
                SizedBox(height: mq.h(0.02)),

                _buildGeofenceMonitoringCard(mq),

                if (_latestZoneEvent != null) ...[
                  SizedBox(height: mq.h(0.02)),
                  _buildZoneStatusCard(mq),
                ],

                SizedBox(height: mq.h(0.02)),
                _buildSafeZonesCard(mq),
                
                SizedBox(height: mq.h(0.02)),
                
                // Feature Cards
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: AppColors.darkCyan),
                  title: const Text('Screen Time'),
                  subtitle: const Text('View your daily usage'),
                  onTap: () {
                    // TODO: Implement screen time feature
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: AppColors.darkCyan),
                  title: const Text('Location'),
                  subtitle: const Text('Share location with parent'),
                  onTap: () {
                    // Navigate to permissions to enable background location first
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChildPermissionsScreen(),
                      ),
                    );
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.emergency, color: AppColors.darkCyan),
                  title: const Text('SOS'),
                  subtitle: const Text('Emergency contact'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SOSEmergencyScreen(),
                      ),
                    );
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone_android, color: AppColors.darkCyan),
                  title: const Text('Installed Apps'),
                  subtitle: const Text('View all installed apps on your device'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChildInstalledAppsScreen(),
                      ),
                    );
                  },
                ),
              ),
              
              // Debug buttons for testing
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final messageDataSource = MessageRemoteDataSourceImpl(
                          firestore: FirebaseFirestore.instance,
                        );
                        await messageDataSource.resetMessageTimestamp(FirebaseAuth.instance.currentUser!.uid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message timestamp reset!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error resetting timestamp: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset Timestamp'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final messageDataSource = MessageRemoteDataSourceImpl(
                          firestore: FirebaseFirestore.instance,
                        );
                        await messageDataSource.monitorChildMessages(
                          parentId: 'test_parent',
                          childId: FirebaseAuth.instance.currentUser!.uid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message monitoring triggered!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error monitoring messages: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check Messages'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final callLogDataSource = CallLogRemoteDataSourceImpl(
                          firestore: FirebaseFirestore.instance,
                        );
                        await callLogDataSource.monitorChildCallLogs(
                          parentId: 'test_parent',
                          childId: FirebaseAuth.instance.currentUser!.uid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Call log monitoring triggered!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error monitoring call logs: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check Call Logs'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final callLogDataSource = CallLogRemoteDataSourceImpl(
                          firestore: FirebaseFirestore.instance,
                        );
                        await callLogDataSource.resetCallLogTimestamp(FirebaseAuth.instance.currentUser!.uid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Call log timestamp reset!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error resetting call log timestamp: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset Call Logs'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final callLogDataSource = CallLogRemoteDataSourceImpl(
                          firestore: FirebaseFirestore.instance,
                        );
                        await callLogDataSource.forceResetAndProcess(
                          'test_parent',
                          FirebaseAuth.instance.currentUser!.uid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📞 Processing last 1 day call logs!'),
                            backgroundColor: Colors.indigo,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error processing call logs: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Process Call Logs'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final messageDataSource = MessageRemoteDataSourceImpl(
                          firestore: FirebaseFirestore.instance,
                        );
                        await messageDataSource.forceResetAndProcess(
                          'test_parent',
                          FirebaseAuth.instance.currentUser!.uid,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔄 Processing last 1 day messages!'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error processing messages: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Process Messages'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final messageDataSource = MessageRemoteDataSourceImpl(
                          firestore: FirebaseFirestore.instance,
                        );
                        await messageDataSource.resetMessageTimestamp(FirebaseAuth.instance.currentUser!.uid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔄 Timestamp reset! Now processing...'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        // Auto-process after reset
                        await Future.delayed(const Duration(seconds: 1));
                        await messageDataSource.forceResetAndProcess(
                          'test_parent',
                          FirebaseAuth.instance.currentUser!.uid,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error resetting: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Force Reset'),
                  ),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildGeofenceMonitoringCard(MQ mq) {
    return Card(
      child: ListTile(
        leading: Icon(
          _isGeofencingMonitoring ? Icons.shield_moon : Icons.shield_outlined,
          color: _isGeofencingMonitoring ? Colors.green : Colors.orange,
        ),
        title: Text(
          _isGeofencingMonitoring ? 'Safe Zone Monitoring Active' : 'Safe Zone Monitoring Inactive',
        ),
        subtitle: Text(
          _isGeofencingMonitoring
              ? 'We’ll alert you and your parent if you leave a safe zone.'
              : 'Enable this to see parent-defined safe zones and get alerts.',
        ),
        trailing: Switch(
          value: _isGeofencingMonitoring,
          onChanged: (value) async {
            if (value) {
              await _startGeofencingMonitoring();
            } else {
              await _stopGeofencingMonitoring();
            }
          },
        ),
      ),
    );
  }

  Widget _buildZoneStatusCard(MQ mq) {
    if (_latestZoneEvent == null) {
      return const SizedBox.shrink();
    }

    final entered = _latestZoneEvent!.eventType == ZoneEventType.enter;
    final icon = entered ? Icons.check_circle : Icons.warning_rounded;
    final color = entered ? Colors.green : Colors.red;
    final title = entered
        ? 'You are inside ${_latestZoneEvent!.zoneName}'
        : 'You left ${_latestZoneEvent!.zoneName}';

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(
          'Updated ${DateFormat('MMM d • h:mm a').format(_latestZoneEvent!.occurredAt)}',
        ),
      ),
    );
  }

  Widget _buildSafeZonesCard(MQ mq) {
    if (_isLoadingZones) {
      return const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Loading safe zones...'),
        ),
      );
    }

    if (_activeZones.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.shield_outlined, color: AppColors.darkCyan),
          title: const Text('No Safe Zones Yet'),
          subtitle: const Text('Your parent has not configured safe zones.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(mq.w(0.03)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Safe Zones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ..._activeZones.map((zone) {
              final isInside = _zoneStatusById[zone.id] == ZoneEventType.enter;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isInside ? Icons.place : Icons.place_outlined,
                  color: isInside ? Colors.green : Colors.grey,
                ),
                title: Text(zone.name),
                subtitle: Text(
                  '${zone.radiusMeters.round()} m radius • ${zone.description ?? 'No description'}',
                ),
                trailing: Text(
                  isInside ? 'Inside' : 'Outside',
                  style: TextStyle(
                    color: isInside ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

