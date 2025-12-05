import 'package:flutter/material.dart';
import '../../../../core/services/qr_code_service.dart';
import '../../../../core/widgets/qr_scanner_widget.dart';
import '../../../user_management/data/models/parent_model.dart';
import '../../../user_management/data/models/child_model.dart';
import 'messages_demo_page.dart';
import 'location_tracking_page.dart';
import 'child_qr_scanner_page.dart';

class QRDemoNewStructurePage extends StatefulWidget {
  final ParentModel? currentParent;

  const QRDemoNewStructurePage({
    super.key,
    this.currentParent,
  });

  @override
  State<QRDemoNewStructurePage> createState() => _QRDemoNewStructurePageState();
}

class _QRDemoNewStructurePageState extends State<QRDemoNewStructurePage> {
  String? scannedData;
  Map<String, dynamic>? scannedQRData;
  ParentModel? currentParent;
  List<ChildModel> children = [];

  @override
  void initState() {
    super.initState();
    currentParent = widget.currentParent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Demo - New Structure'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Parent Creator
            TestParentCreator(
              onParentCreated: (parent) {
                setState(() {
                  currentParent = parent;
                });
              },
            ),
            SizedBox(height: 16),

            // Debug Information
            if (currentParent != null)
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
                      Text('Parent ID: "${currentParent!.parentId}"'),
                      Text('Name: "${currentParent!.name}"'),
                      Text('Email: "${currentParent!.email}"'),
                      Text('Children Count: ${currentParent!.childIds.length}'),
                      Text('Can Generate Family Invites: ${currentParent!.canGenerateFamilyInvites()}'),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Parent Profile QR Section
            if (currentParent != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parent Profile QR Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: QRCodeService.generateUserProfileQR(
                          userData: currentParent!.generateQRData(),
                          size: 200,
                          title: currentParent!.name,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showQRCodeDialog(
                          context,
                          currentParent!.generateQRData(),
                          '${currentParent!.name}\'s Profile',
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
            if (currentParent != null) ...[
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
                      Center(
                        child: QRCodeService.generateFamilyInviteQR(
                          inviteData: currentParent!.generateFamilyInviteQRData(),
                          size: 200,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showQRCodeDialog(
                          context,
                          currentParent!.generateFamilyInviteQRData(),
                          'Family Invite',
                        ),
                        icon: Icon(Icons.family_restroom),
                        label: Text('View Full Size'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Add Child Section
            if (currentParent != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Child',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      TestChildCreator(
                        parentId: currentParent!.parentId,
                        onChildCreated: (child) {
                          setState(() {
                            children.add(child);
                            // Update parent's childIds
                            currentParent = currentParent!.addChild(child.childId);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Children List
            if (children.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Children (${children.length})',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      ...children.map((child) => Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(child.name[0].toUpperCase()),
                          ),
                          title: Text(child.name),
                          subtitle: Text(child.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.location_on),
                                  onPressed: () => _openLocationPage(child),
                                ),
                                IconButton(
                                  icon: Icon(Icons.message),
                                  onPressed: () => _openMessagesPage(child),
                                ),
                                IconButton(
                                  icon: Icon(Icons.qr_code),
                                  onPressed: () => _showQRCodeDialog(
                                    context,
                                    child.generateQRData(),
                                    '${child.name}\'s Profile',
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      children.removeWhere((c) => c.childId == child.childId);
                                      currentParent = currentParent!.removeChild(child.childId);
                                    });
                                  },
                                ),
                              ],
                            ),
                        ),
                      )),
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openScanner(context),
                            icon: Icon(Icons.qr_code_scanner),
                            label: Text('Scan QR Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openChildScanner(context),
                            icon: Icon(Icons.family_restroom),
                            label: Text('Join Family'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ],
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

  void _openMessagesPage(ChildModel child) {
    if (currentParent != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesDemoPage(
            parent: currentParent!,
            child: child,
          ),
        ),
      );
    }
  }

  void _openLocationPage(ChildModel child) {
    if (currentParent != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationTrackingPage(
            parent: currentParent!,
            child: child,
          ),
        ),
      );
    }
  }

  void _openChildScanner(BuildContext context) {
    if (currentParent != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChildQRScannerPage(
            parent: currentParent!,
          ),
        ),
      );
    }
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

class TestParentCreator extends StatelessWidget {
  final Function(ParentModel) onParentCreated;

  const TestParentCreator({
    super.key,
    required this.onParentCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Parent Creator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _createTestParent(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: Text('Create Test Parent'),
            ),
          ],
        ),
      ),
    );
  }

  void _createTestParent() {
    final parent = ParentModel(
      parentId: 'parent_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test Parent',
      email: 'parent@example.com',
      userType: 'parent',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    onParentCreated(parent);
  }
}

class TestChildCreator extends StatelessWidget {
  final String parentId;
  final Function(ChildModel) onChildCreated;

  const TestChildCreator({
    super.key,
    required this.parentId,
    required this.onChildCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Child Name',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: 'Test Child'),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Child Email',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: 'child@example.com'),
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _createTestChild(),
          child: Text('Add Child'),
        ),
      ],
    );
  }

  void _createTestChild() {
    final child = ChildModel(
      childId: 'child_${DateTime.now().millisecondsSinceEpoch}',
      parentId: parentId,
      name: 'Test Child',
      email: 'child@example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    onChildCreated(child);
  }
}
