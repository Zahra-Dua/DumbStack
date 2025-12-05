# QR Code Feature

This feature provides QR code generation and scanning functionality for the parental control app.

## Features

- **User Profile QR Codes**: Generate QR codes for user profiles that can be shared
- **Family Invite QR Codes**: Parents can generate QR codes to invite family members
- **Device Pairing QR Codes**: Generate QR codes for device pairing
- **QR Code Scanner**: Scan QR codes with camera
- **Customizable QR Widgets**: Various styled QR code widgets

## Usage

### 1. Generate User Profile QR Code

```dart
// Create a user model
UserModel user = UserModel(
  uid: 'user123',
  name: 'John Doe',
  email: 'john@example.com',
  avatarUrl: 'https://example.com/avatar.jpg',
  userType: 'parent',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Generate QR data
Map<String, dynamic> qrData = user.generateQRData();
String qrString = user.generateQRString();

// Display QR code widget
Widget qrWidget = QRCodeService.generateUserProfileQR(
  userData: qrData,
  size: 200,
  title: 'John Doe',
);
```

### 2. Generate Family Invite QR Code

```dart
// Only parents can generate family invites
if (user.userType.toLowerCase() == 'parent') {
  Map<String, dynamic>? inviteData = user.generateFamilyInviteQRData('family_123');
  if (inviteData != null) {
    Widget inviteQR = QRCodeService.generateFamilyInviteQR(
      inviteData: inviteData,
      size: 200,
    );
  }
}
```

### 3. Scan QR Codes

```dart
// Open QR scanner
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => QRScannerWidget(
      title: 'Scan QR Code',
      subtitle: 'Point your camera at a QR code',
      onQRCodeDetected: (data) {
        print('Scanned data: $data');
        // Handle scanned data
      },
    ),
  ),
);
```

### 4. Simple QR Code Widget

```dart
// Generate a simple QR code
Widget simpleQR = QRCodeService.generateQRWidget(
  data: 'Hello World!',
  size: 150,
  foregroundColor: Colors.blue,
  backgroundColor: Colors.white,
);
```

## Integration

To add QR code functionality to your existing screens:

1. Import the QR code button:
```dart
import 'package:parental_control_app/features/qr_code/presentation/widgets/qr_code_button.dart';
```

2. Add the button to your widget:
```dart
QRCodeButton(
  currentUser: currentUser, // Your current user model
  label: 'QR Codes',
  icon: Icons.qr_code,
)
```

## QR Code Data Format

The generated QR codes contain JSON data with the following structure:

### User Profile QR
```json
{
  "type": "user_profile",
  "uid": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "userType": "parent",
  "timestamp": 1234567890
}
```

### Family Invite QR
```json
{
  "type": "family_invite",
  "familyId": "family_123",
  "inviterName": "John Doe",
  "inviterEmail": "john@example.com",
  "timestamp": 1234567890
}
```

### Device Pairing QR
```json
{
  "type": "device_pairing",
  "deviceId": "device_123",
  "deviceName": "John's Phone",
  "ownerUid": "user123",
  "timestamp": 1234567890
}
```

## Dependencies

The QR code feature uses the following packages:
- `qr_flutter: ^4.0.0` - For QR code generation
- `mobile_scanner: ^7.0.1` - For QR code scanning

These are already included in your `pubspec.yaml` file.
