import 'package:flutter/material.dart';
import '../pages/qr_demo_page.dart';
import '../../../user_management/data/models/user_model.dart';

class QRCodeButton extends StatelessWidget {
  final UserModel? currentUser;
  final String? label;
  final IconData? icon;

  const QRCodeButton({
    super.key,
    this.currentUser,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRDemoPage(currentUser: currentUser),
          ),
        );
      },
      icon: Icon(icon ?? Icons.qr_code),
      label: Text(label ?? 'QR Codes'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
