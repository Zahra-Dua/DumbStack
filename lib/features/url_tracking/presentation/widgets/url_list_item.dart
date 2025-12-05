import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/visited_url.dart';

class UrlListItem extends StatelessWidget {
  final VisitedUrl url;
  final VoidCallback onTap;
  final Function(bool) onBlockToggle;
  final VoidCallback onDelete;

  const UrlListItem({
    super.key,
    required this.url,
    required this.onTap,
    required this.onBlockToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isPlaceholder = url.url == 'Browser Activity Detected' || url.url.isEmpty;

    // Don't show empty or placeholder URLs
    if (isPlaceholder) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPlaceholder ? Colors.orange : 
                         url.isBlocked ? Colors.red : Colors.blue,
          child: Icon(
            isPlaceholder ? Icons.browser_updated : 
            url.isBlocked ? Icons.block : Icons.language,
            color: Colors.white,
          ),
        ),
        title: Text(
          isPlaceholder ? 'Browser Activity' : _getSiteName(url.url, url.title),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: url.isBlocked ? Colors.red : 
                   isPlaceholder ? Colors.orange : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isPlaceholder) Text(
              url.url,
              style: TextStyle(
                color: url.isBlocked ? Colors.red[300] : Colors.blue[600],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${dateFormat.format(url.visitedAt)} at ${timeFormat.format(url.visitedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getBrowserDisplayName(url.packageName),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'visit':
                onTap();
                break;
              case 'block':
                onBlockToggle(!url.isBlocked);
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'visit',
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_browser,
                    color: url.isBlocked ? Colors.grey : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Visit URL',
                    style: TextStyle(
                      color: url.isBlocked ? Colors.grey : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(
                    url.isBlocked ? Icons.lock_open : Icons.block,
                    color: url.isBlocked ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(url.isBlocked ? 'Unblock' : 'Block'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: url.isBlocked ? () => _showBlockedUrlInfo(context) : onTap,
      ),
    );
  }


  String _getSiteName(String url, String title) {
    // If title contains useful site name, use it
    if (title.isNotEmpty && !title.contains(' - ') && !title.contains('Browser')) {
      return title;
    }
    
    // Extract site name from URL
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      // Remove www. prefix
      final cleanHost = host.startsWith('www.') ? host.substring(4) : host;
      
      // Get the main domain part (before first dot)
      final parts = cleanHost.split('.');
      if (parts.isNotEmpty) {
        final siteName = parts[0];
        
        // Capitalize first letter
        return siteName.isNotEmpty 
            ? '${siteName[0].toUpperCase()}${siteName.substring(1)}'
            : cleanHost;
      }
      
      return cleanHost;
    } catch (e) {
      return url;
    }
  }

  String _getBrowserDisplayName(String packageName) {
    switch (packageName) {
      case 'com.android.chrome':
        return 'Chrome';
      case 'org.mozilla.firefox':
        return 'Firefox';
      case 'com.microsoft.emmx':
        return 'Edge';
      case 'com.opera.browser':
        return 'Opera';
      case 'com.sec.android.app.sbrowser':
        return 'Samsung';
      case 'com.UCMobile.intl':
        return 'UC Browser';
      case 'com.brave.browser':
        return 'Brave';
      default:
        return packageName.split('.').last;
    }
  }

  void _showBlockedUrlInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('URL Blocked'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This URL is currently blocked:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                url.url,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.red[800],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'To unblock this URL, use the menu options above.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBlockToggle(false); // Unblock the URL
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Unblock Now'),
          ),
        ],
      ),
    );
  }
}
