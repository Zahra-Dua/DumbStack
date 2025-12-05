import 'package:flutter/material.dart';
import 'package:parental_control_app/core/constants/app_assets.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';

class ResponsiveLogo extends StatelessWidget {
  final double sizeFactor; // fraction of screen width, e.g. 0.2

  const ResponsiveLogo({super.key, this.sizeFactor = 0.22});

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    final logoSize = mq.w(sizeFactor);
    return Column(
      children: [
        Image.asset(AppAssets.logo, width: logoSize, height: logoSize, fit: BoxFit.contain),
      ],
    );
  }
}
