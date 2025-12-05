import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_query_helpers.dart';
import '../../data/models/location_model.dart';

class ChildLocationCard extends StatelessWidget {
  final String childName;
  final int childAge;
  final String childGender;
  final LocationModel? location;
  final bool isSelected;

  const ChildLocationCard({
    super.key,
    required this.childName,
    required this.childAge,
    required this.childGender,
    this.location,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);
    
    return Container(
      width: 150,
      margin: EdgeInsets.only(right: mq.w(0.03)),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.darkCyan : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mq.w(0.03)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected ? Colors.white : AppColors.darkCyan,
                  child: Icon(
                    childGender.toLowerCase() == 'female' ? Icons.person : Icons.person_outline,
                    color: isSelected ? AppColors.darkCyan : Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: mq.w(0.02)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: TextStyle(
                          fontSize: mq.sp(0.04),
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Age: $childAge',
                        style: TextStyle(
                          fontSize: mq.sp(0.035),
                          color: isSelected ? Colors.white70 : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: mq.h(0.01)),
            
            // Location Status
            if (location != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.green,
                  ),
                  SizedBox(width: mq.w(0.01)),
                  Expanded(
                    child: Text(
                      'Online',
                      style: TextStyle(
                        fontSize: mq.sp(0.035),
                        color: isSelected ? Colors.white : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mq.h(0.005)),
              Text(
                location!.address,
                style: TextStyle(
                  fontSize: mq.sp(0.03),
                  color: isSelected ? Colors.white70 : AppColors.textLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 16,
                    color: isSelected ? Colors.white70 : Colors.grey,
                  ),
                  SizedBox(width: mq.w(0.01)),
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontSize: mq.sp(0.035),
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
