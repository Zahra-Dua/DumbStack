import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../../../core/di/service_locator.dart';
import '../bloc/report_bloc.dart';
import '../pages/reports_list_screen.dart';

class ReportCardWidget extends StatelessWidget {
  final String childId;
  final String childName;
  final String parentId;

  const ReportCardWidget({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: mq.w(0.04), vertical: mq.h(0.01)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => sl<ReportBloc>(),
                  child: ReportsListScreen(
                    childId: childId,
                    childName: childName,
                    parentId: parentId,
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(mq.w(0.04)),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assessment,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                SizedBox(width: mq.w(0.03)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Reports',
                        style: TextStyle(
                          fontSize: mq.sp(0.05),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: mq.h(0.005)),
                      Text(
                        'Generate and view $childName\'s activity reports',
                        style: TextStyle(
                          fontSize: mq.sp(0.04),
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textLight,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

