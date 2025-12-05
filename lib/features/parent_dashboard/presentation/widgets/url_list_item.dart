import 'package:flutter/material.dart';
import '../../../url_tracking/data/models/visited_url_firebase.dart';

class UrlListItem extends StatelessWidget {
  final VisitedUrlFirebase url;
  final VoidCallback? onTap;
  final Function(bool)? onBlockToggle;
  final VoidCallback? onDelete;

  const UrlListItem({
    super.key,
    required this.url,
    this.onTap,
    this.onBlockToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // URL Icon with threat indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: url.isMalicious 
                        ? Colors.red[100] 
                        : url.isSpam 
                            ? Colors.orange[100] 
                            : url.isBlocked 
                                ? Colors.red[100] 
                                : Colors.blue[100],
                    child: Icon(
                      url.isMalicious 
                          ? Icons.dangerous 
                          : url.isSpam 
                              ? Icons.warning 
                              : url.isBlocked 
                                  ? Icons.block 
                                  : Icons.language,
                      color: url.isMalicious 
                          ? Colors.red 
                          : url.isSpam 
                              ? Colors.orange 
                              : url.isBlocked 
                                  ? Colors.red 
                                  : Colors.blue,
                      size: 20,
                    ),
                  ),
                  if (url.isMalicious || url.isSpam)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12),
              
              // URL Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          flex: 3,
                          child: Text(
                            url.title.isNotEmpty ? url.title : _getDomainFromUrl(url.url),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: url.isMalicious 
                                  ? Colors.red[700] 
                                  : url.isSpam 
                                      ? Colors.orange[700] 
                                      : url.isBlocked 
                                          ? Colors.red[700] 
                                          : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (url.isMalicious)
                          Flexible(
                            flex: 0,
                            child: Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'MALICIOUS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        else if (url.isSpam)
                          Flexible(
                            flex: 0,
                            child: Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SPAM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      url.url,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDateTime(url.visitedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (url.browserName != null) ...[
                          SizedBox(width: 8),
                          Icon(Icons.web, size: 12, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              url.browserName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBlockToggle != null)
                    IconButton(
                      icon: Icon(
                        url.isBlocked ? Icons.lock_open : Icons.block,
                        color: url.isBlocked ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      onPressed: () => onBlockToggle!(!url.isBlocked),
                      tooltip: url.isBlocked ? 'Unblock' : 'Block',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red[400],
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDomainFromUrl(String url) {
    try {
      String normalizedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        normalizedUrl = 'https://$url';
      }
      final uri = Uri.parse(normalizedUrl);
      return uri.host.toLowerCase();
    } catch (e) {
      return url.toLowerCase();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}
