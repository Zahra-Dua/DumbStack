import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QRCodeService {
  /// Generate QR code data for user profile sharing
  static Map<String, dynamic> generateUserProfileQRData({
    required String uid,
    required String name,
    required String email,
    required String userType,
  }) {
    return {
      'type': 'user_profile',
      'uid': uid,
      'name': name,
      'email': email,
      'userType': userType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Generate QR code data for family invite
  static Map<String, dynamic> generateFamilyInviteQRData({
    required String familyId,
    required String inviterName,
    required String inviterEmail,
  }) {
    return {
      'type': 'family_invite',
      'familyId': familyId,
      'inviterName': inviterName,
      'inviterEmail': inviterEmail,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Generate QR code data for device pairing
  static Map<String, dynamic> generateDevicePairingQRData({
    required String deviceId,
    required String deviceName,
    required String ownerUid,
  }) {
    return {
      'type': 'device_pairing',
      'deviceId': deviceId,
      'deviceName': deviceName,
      'ownerUid': ownerUid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Convert data to JSON string for QR code
  static String dataToJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Parse QR code JSON string back to data
  static Map<String, dynamic>? jsonToData(String jsonString) {
    try {
      // Check if the string looks like JSON (starts with { or [)
      if (jsonString.trim().startsWith('{') || jsonString.trim().startsWith('[')) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } else {
        print('String does not look like JSON: $jsonString');
        return null;
      }
    } catch (e) {
      print('JSON parsing error: $e');
      return null;
    }
  }

  /// Generate QR code widget
  static Widget generateQRWidget({
    required String data,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
    String? errorText,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      errorStateBuilder: (context, error) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: size * 0.3,
                ),
                SizedBox(height: 8),
                Text(
                  errorText ?? 'QR Code Error',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Generate QR code with custom styling for user profiles
  static Widget generateUserProfileQR({
    required Map<String, dynamic> userData,
    double size = 200.0,
    String? title,
  }) {
    final qrData = dataToJson(userData);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
          ],
          generateQRWidget(
            data: qrData,
            size: size,
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            'Scan to add user',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Generate QR code for family invites
  static Widget generateFamilyInviteQR({
    required Map<String, dynamic> inviteData,
    double size = 200.0,
  }) {
    final qrData = dataToJson(inviteData);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.family_restroom,
            color: Colors.blue[700],
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Family Invite',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 12),
          generateQRWidget(
            data: qrData,
            size: size,
            foregroundColor: Colors.blue[800],
            backgroundColor: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            'Scan to join family',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }
}
