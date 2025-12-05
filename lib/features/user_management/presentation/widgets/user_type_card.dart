import 'package:flutter/material.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';

class UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final String buttonText;
  final VoidCallback onPressed;

  const UserTypeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.onPressed,
  });

  Widget _featureRow(String text, BuildContext context) {
    final mq = MQ(context);
    return Row(
      children: [
        Icon(Icons.check_circle, size: mq.w(0.04), color: AppColors.deepTeal),
        SizedBox(width: mq.w(0.02)),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: mq.sp(0.032))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: mq.w(0.05),
        vertical: mq.h(0.03),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: mq.w(0.07),
                backgroundColor: AppColors.lightCyan,
                child: Icon(icon, size: mq.w(0.07), color: AppColors.darkCyan),
              ),
              SizedBox(width: mq.w(0.04)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: mq.sp(0.05),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: mq.h(0.005)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: mq.sp(0.034),
                      color: AppColors.darkCyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: mq.h(0.02)),
          Text(
            description,
            style: TextStyle(
              fontSize: mq.sp(0.033),
              color: AppColors.black.withOpacity(0.7),
            ),
          ),
          SizedBox(height: mq.h(0.015)),
          Column(
            children: features
                .map(
                  (f) => Padding(
                    padding: EdgeInsets.symmetric(vertical: mq.h(0.006)),
                    child: _featureRow(f, context),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: mq.h(0.02)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCyan,
                padding: EdgeInsets.symmetric(vertical: mq.h(0.018)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: mq.sp(0.038),
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
