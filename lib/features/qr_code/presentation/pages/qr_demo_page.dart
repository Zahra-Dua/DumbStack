import 'package:flutter/material.dart';
import '../../../../core/services/qr_code_service.dart';
import '../../../../core/widgets/qr_scanner_widget.dart';
import '../../../user_management/data/models/user_model.dart';
import '../widgets/test_user_creator.dart';

class QRDemoPage extends StatefulWidget {
  final UserModel? currentUser;

  const QRDemoPage({
    super.key,
    this.currentUser,
  });

  @override
  State<QRDemoPage> createState() => _QRDemoPageState();
}

class _QRDemoPageState extends State<QRDemoPage> {
  String? scannedData;
  Map<String, dynamic>? scannedQRData;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Demo'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test User Creator
            TestUserCreator(
              onUserCreated: (user) {
                setState(() {
                  currentUser = user;
                });
              },
            ),
            SizedBox(height: 16),

            // Debug Information
            if (currentUser != null)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('User Type: "${currentUser!.userType}"'),
                      Text('Display Type: "${currentUser!.displayUserType}"'),
                      Text('Can Generate Family Invites: ${currentUser!.canGenerateFamilyInvites()}'),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // User Profile QR Section
            if (currentUser != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Profile QR Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: QRCodeService.generateUserProfileQR(
                          userData: currentUser!.generateQRData(),
                          size: 200,
                          title: currentUser!.name,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showQRCodeDialog(
                          context,
                          currentUser!.generateQRData(),
                          '${currentUser!.name}\'s Profile',
                        ),
                        icon: Icon(Icons.qr_code),
                        label: Text('View Full Size'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Family Invite QR Section
            if (currentUser?.canGenerateFamilyInvites() == true) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Family Invite QR Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final inviteData = currentUser!.generateFamilyInviteQRData('family_123');
                          if (inviteData == null) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Unable to generate family invite',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return QRCodeService.generateFamilyInviteQR(
                            inviteData: inviteData,
                            size: 200,
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final inviteData = currentUser!.generateFamilyInviteQRData('family_123');
                          return ElevatedButton.icon(
                            onPressed: inviteData != null ? () => _showQRCodeDialog(
                              context,
                              inviteData,
                              'Family Invite',
                            ) : null,
                            icon: Icon(Icons.family_restroom),
                            label: Text('View Full Size'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Scanner Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Scanner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openScanner(context),
                      icon: Icon(Icons.qr_code_scanner),
                      label: Text('Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    if (scannedData != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scanned Data:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              scannedData!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            if (scannedQRData != null) ...[
                              SizedBox(height: 8),
                              Text(
                                'Parsed Data:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Type: ${scannedQRData!['type'] ?? 'Unknown'}',
                                style: TextStyle(fontSize: 12),
                              ),
                              if (scannedQRData!['name'] != null)
                                Text(
                                  'Name: ${scannedQRData!['name']}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              if (scannedQRData!['email'] != null)
                                Text(
                                  'Email: ${scannedQRData!['email']}',
                                  style: TextStyle(fontSize: 12),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Sample QR Codes
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample QR Codes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Simple Text QR'),
                              SizedBox(height: 8),
                              QRCodeService.generateQRWidget(
                                data: 'Hello World!',
                                size: 120,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Text('URL QR'),
                              SizedBox(height: 8),
                              QRCodeService.generateQRWidget(
                                data: 'https://flutter.dev',
                                size: 120,
                                foregroundColor: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          title: 'Scan QR Code',
          subtitle: 'Point your camera at a QR code to scan it',
          onQRCodeDetected: (data) {
            setState(() {
              scannedQRData = data;
              scannedData = data.toString();
            });
          },
        ),
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, Map<String, dynamic> data, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              QRCodeService.generateQRWidget(
                data: QRCodeService.dataToJson(data),
                size: 250,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share functionality coming soon!')),
                      );
                    },
                    icon: Icon(Icons.share),
                    label: Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
