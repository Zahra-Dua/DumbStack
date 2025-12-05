import 'package:flutter/material.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    return Scaffold(
      backgroundColor: AppColors.lightCyan,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.w(0.06)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mail_outline,
                size: mq.w(0.22),
                color: AppColors.deepTeal,
              ),
              SizedBox(height: mq.h(0.03)),
              Text(
                'Check your email',
                style: TextStyle(
                  fontSize: mq.sp(0.07),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: mq.h(0.02)),
              Text(
                'We have sent a password reset link. Open the link and it should open the app to reset your password. If it opens a web page, copy the code (oobCode) and paste it into the Reset Password screen.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: mq.h(0.03)),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkCyan,
                  padding: EdgeInsets.symmetric(vertical: mq.h(0.018)),
                ),
                child: Text('Back', style: TextStyle(fontSize: mq.sp(0.038))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
