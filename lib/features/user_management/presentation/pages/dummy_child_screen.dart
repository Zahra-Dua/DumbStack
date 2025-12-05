import 'package:flutter/material.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import 'package:parental_control_app/features/user_management/presentation/pages/child_scan_qr_screen.dart';

class DummyChildScreen extends StatelessWidget {
  const DummyChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      appBar: AppBar(
        backgroundColor: AppColors.lightCyan,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.w(0.06)),
          child: Column(
            children: [
              SizedBox(height: mq.h(0.06)),
              Icon(
                Icons.qr_code_scanner,
                size: mq.w(0.22),
                color: AppColors.deepTeal,
              ),
              SizedBox(height: mq.h(0.03)),
              Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: mq.sp(0.07),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: mq.h(0.02)),
              Text(
                'Open the SafeNest parent app and scan the QR code to connect your device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: mq.sp(0.035)),
              ),
              SizedBox(height: mq.h(0.03)),
              ElevatedButton(
                onPressed: () {
                  // TODO: implement QR scanner
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChildScanQRScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkCyan,
                  padding: EdgeInsets.symmetric(vertical: mq.h(0.018)),
                ),
                child: Text(
                  'Scan QR Code',
                  style: TextStyle(fontSize: mq.sp(0.038)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
