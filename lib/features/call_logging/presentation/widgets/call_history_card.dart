import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:parental_control_app/core/constants/app_colors.dart';
import 'package:parental_control_app/core/utils/media_query_helpers.dart';
import '../../data/models/call_log_model.dart';

class CallHistoryCard extends StatelessWidget {
  final CallLogModel callLog;
  final VoidCallback? onTap;

  const CallHistoryCard({
    super.key,
    required this.callLog,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MQ(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: mq.w(0.04), vertical: mq.h(0.01)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(mq.w(0.04)),
            child: Row(
              children: [
                // Call Type Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCallTypeColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCallTypeIcon(),
                    color: _getCallTypeColor(),
                    size: 20,
                  ),
                ),
                
                SizedBox(width: mq.w(0.03)),
                
                // Call Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name or Number
                      Text(
                        callLog.name ?? callLog.number,
                        style: TextStyle(
                          fontSize: mq.sp(0.045),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: mq.h(0.005)),
                      
                      // Number (if name exists)
                      if (callLog.name != null)
                        Text(
                          callLog.number,
                          style: TextStyle(
                            fontSize: mq.sp(0.035),
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      SizedBox(height: mq.h(0.005)),
                      
                      // Call Type and Duration
                      Row(
                        children: [
                          Text(
                            callLog.callTypeString,
                            style: TextStyle(
                              fontSize: mq.sp(0.032),
                              color: _getCallTypeColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (callLog.duration > 0) ...[
                            SizedBox(width: mq.w(0.02)),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: mq.sp(0.032),
                                color: AppColors.textLight,
                              ),
                            ),
                            SizedBox(width: mq.w(0.02)),
                            Text(
                              callLog.durationString,
                              style: TextStyle(
                                fontSize: mq.sp(0.032),
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(callLog.dateTime),
                      style: TextStyle(
                        fontSize: mq.sp(0.035),
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: mq.h(0.005)),
                    Text(
                      _formatDate(callLog.dateTime),
                      style: TextStyle(
                        fontSize: mq.sp(0.03),
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCallTypeColor() {
    switch (callLog.type) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
      case CallType.rejected:
        return Colors.red.shade300;
      case CallType.blocked:
        return Colors.grey;
      case CallType.answeredExternally:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCallTypeIcon() {
    switch (callLog.type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      case CallType.rejected:
        return Icons.call_end;
      case CallType.blocked:
        return Icons.block;
      case CallType.answeredExternally:
        return Icons.call_split;
      default:
        return Icons.call;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
