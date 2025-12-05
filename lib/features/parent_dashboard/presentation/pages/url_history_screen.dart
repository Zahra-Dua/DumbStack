import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../url_tracking/data/models/visited_url_firebase.dart';
import '../../../url_blocking/data/services/url_blocking_firebase_service.dart';
import '../../../url_blocking/data/models/blocked_url_rule.dart';
import '../widgets/url_list_item.dart';
import '../../data/services/parent_dashboard_firebase_service.dart';

class UrlHistoryScreen extends StatefulWidget {
  final List<VisitedUrlFirebase> urls;
  final String childId;
  final String parentId;

  const UrlHistoryScreen({
    super.key,
    required this.urls,
    required this.childId,
    required this.parentId,
  });

  @override
  State<UrlHistoryScreen> createState() => _UrlHistoryScreenState();
}

class _UrlHistoryScreenState extends State<UrlHistoryScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, safe, blocked, malicious, spam
  final ParentDashboardFirebaseService _firebaseService = ParentDashboardFirebaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VisitedUrlFirebase>>(
      stream: _firebaseService.getVisitedUrlsStream(
        childId: widget.childId,
        parentId: widget.parentId,
      ),
      builder: (context, snapshot) {
        final allUrls = snapshot.hasData ? snapshot.data! : <VisitedUrlFirebase>[];
        final filteredCount = snapshot.hasData 
            ? allUrls.where((url) {
                final matchesSearch = url.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                    url.title.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesFilter = _filterType == 'all' ||
                                   (_filterType == 'safe' && !url.isBlocked && !url.isMalicious && !url.isSpam) ||
                                   (_filterType == 'blocked' && url.isBlocked) ||
                                   (_filterType == 'malicious' && url.isMalicious) ||
                                   (_filterType == 'spam' && url.isSpam);
                return matchesSearch && matchesFilter;
              }).length
            : 0;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('URL History ($filteredCount/${allUrls.length})'),
            backgroundColor: Colors.blue[100],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildStatBadge(
                      'Total',
                      allUrls.length.toString(),
                      Colors.blue,
                    ),
                    SizedBox(width: 8),
                    _buildStatBadge(
                      'Malicious',
                      allUrls.where((u) => u.isMalicious).length.toString(),
                      Colors.red,
                    ),
                    SizedBox(width: 8),
                    _buildStatBadge(
                      'Spam',
                      allUrls.where((u) => u.isSpam).length.toString(),
                      Colors.orange,
                    ),
                    SizedBox(width: 8),
                    _buildStatBadge(
                      'Blocked',
                      allUrls.where((u) => u.isBlocked).length.toString(),
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filterType = 'all';
                  });
                },
              ),
            ],
          ),
          body: StreamBuilder<List<VisitedUrlFirebase>>(
        stream: _firebaseService.getVisitedUrlsStream(
          childId: widget.childId,
          parentId: widget.parentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading URLs: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Get URLs from snapshot
          final allUrls = snapshot.hasData ? snapshot.data! : <VisitedUrlFirebase>[];
          
          // Filter URLs based on search and filter criteria
          final filteredUrls = allUrls.where((url) {
            final matchesSearch = url.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                url.title.toLowerCase().contains(_searchQuery.toLowerCase());
            
            final matchesFilter = _filterType == 'all' ||
                               (_filterType == 'safe' && !url.isBlocked && !url.isMalicious && !url.isSpam) ||
                               (_filterType == 'blocked' && url.isBlocked) ||
                               (_filterType == 'malicious' && url.isMalicious) ||
                               (_filterType == 'spam' && url.isSpam);
            
            return matchesSearch && matchesFilter;
          }).toList();
          
          // Sort: malicious and spam URLs first
          filteredUrls.sort((a, b) {
            if (a.isMalicious && !b.isMalicious) return -1;
            if (!a.isMalicious && b.isMalicious) return 1;
            if (a.isSpam && !b.isSpam) return -1;
            if (!a.isSpam && b.isSpam) return 1;
            return b.visitedAt.compareTo(a.visitedAt);
          });
          
          if (snapshot.hasData) {
            print('✅ Real-time update: ${allUrls.length} URLs loaded');
          }
          
          return Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search URLs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 12),
                // Filter Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Safe', 'safe'),
                    _buildFilterChip('Blocked', 'blocked'),
                    _buildFilterChip('🚨 Malicious', 'malicious'),
                    _buildFilterChip('⚠️ Spam', 'spam'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Spacer(),
                    // Bulk Actions
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (value) => _handleBulkAction(value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'block_all',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Block All'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'unblock_all',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Unblock All'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete All'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
                  // URL List
                  Expanded(
                    child: filteredUrls.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.language,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No URLs found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (_searchQuery.isNotEmpty || _filterType != 'all')
                                      Text(
                                        'Try adjusting your search or filter',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      )
                                    else
                                      Text(
                                        'Child has not visited any URLs yet',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredUrls.length,
                                itemBuilder: (context, index) {
                                  final url = filteredUrls[index];
                                  return UrlListItem(
                                    url: url,
                                    onTap: () => _launchUrl(url.url),
                                    onBlockToggle: (isBlocked) => _toggleUrlBlock(url, isBlocked),
                                    onDelete: () => _deleteUrl(url),
                                  );
                                },
                              ),
                  ),
        ],
          );
        },
      ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  void _handleBulkAction(String action) async {
    // Get current URLs from stream
    final urlsSnapshot = await _firebaseService.getVisitedUrlsStream(
      childId: widget.childId,
      parentId: widget.parentId,
    ).first;
    
    final allUrls = urlsSnapshot;
    
    // Filter URLs based on current filter
    final filteredUrls = allUrls.where((url) {
      final matchesSearch = url.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          url.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterType == 'all' ||
                         (_filterType == 'safe' && !url.isBlocked && !url.isMalicious && !url.isSpam) ||
                         (_filterType == 'blocked' && url.isBlocked) ||
                         (_filterType == 'malicious' && url.isMalicious) ||
                         (_filterType == 'spam' && url.isSpam);
      return matchesSearch && matchesFilter;
    }).toList();
    
    switch (action) {
      case 'block_all':
        _showBulkActionDialog('Block All URLs', 'Are you sure you want to block all URLs?', () async {
          for (var url in filteredUrls) {
            await _firebaseService.updateUrlBlockStatus(
              childId: widget.childId,
              parentId: widget.parentId,
              urlId: url.id,
              isBlocked: true,
            );
          }
          setState(() {});
        });
        break;
      case 'unblock_all':
        _showBulkActionDialog('Unblock All URLs', 'Are you sure you want to unblock all URLs?', () async {
          for (var url in filteredUrls) {
            await _firebaseService.updateUrlBlockStatus(
              childId: widget.childId,
              parentId: widget.parentId,
              urlId: url.id,
              isBlocked: false,
            );
          }
          setState(() {});
        });
        break;
      case 'delete_all':
        _showBulkActionDialog('Delete All URLs', 'Are you sure you want to delete all URLs? This action cannot be undone.', () async {
          for (var url in filteredUrls) {
            await _firebaseService.deleteUrl(
              childId: widget.childId,
              parentId: widget.parentId,
              urlId: url.id,
            );
          }
          setState(() {});
        });
        break;
    }
  }

  void _showBulkActionDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _toggleUrlBlock(VisitedUrlFirebase url, bool isBlocked) async {
    // Import the blocking service
    final blockingService = UrlBlockingFirebaseService();
    
    if (isBlocked) {
      // Block the URL using the blocking service
      try {
        await blockingService.blockUrl(
          childId: widget.childId,
          parentId: widget.parentId,
          url: url.url,
          reason: url.isMalicious 
              ? 'Malicious content detected' 
              : url.isSpam 
                  ? 'Spam content detected'
                  : 'Blocked by parent',
          blockType: BlockType.domain, // Block entire domain
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL blocked successfully. Child device will be notified.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error blocking URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Unblock: Find the block rule and remove it
      try {
        final blockedUrls = await blockingService.getBlockedUrls(
          childId: widget.childId,
          parentId: widget.parentId,
        );
        
        final matchingRule = blockedUrls.firstWhere(
          (rule) => rule.matches(url.url),
          orElse: () => throw Exception('Block rule not found'),
        );
        
        await blockingService.unblockUrl(
          childId: widget.childId,
          parentId: widget.parentId,
          urlId: matchingRule.id,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL unblocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unblocking URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() {});
  }

  void _deleteUrl(VisitedUrlFirebase url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete URL'),
        content: Text('Are you sure you want to delete this URL?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _firebaseService.deleteUrl(
                childId: widget.childId,
                parentId: widget.parentId,
                urlId: url.id,
              );
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('URL deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch URL: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
