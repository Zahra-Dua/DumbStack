import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/services/recommendation_service.dart';

/// Recommendations Tab
/// 
/// Shows AI-generated recommendations for all children
class RecommendationsTab extends StatefulWidget {
  final String parentId;

  const RecommendationsTab({
    super.key,
    required this.parentId,
  });

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> with WidgetsBindingObserver {
  final RecommendationService _recommendationService = RecommendationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all'; // 'all', 'pending', 'approved', 'rejected'
  Timer? _timer;
  DateTime? _nextGenerationTime; // Store the absolute time when next generation should happen
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recommendationService.initialize();
    _loadNextGenerationTime(); // Load saved time instead of initializing
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 [RecommendationsTab] App resumed - reloading timer');
      // Reload timer when app comes to foreground
      _loadNextGenerationTime();
      setState(() {});
    }
  }

  /// Load next generation time from SharedPreferences
  /// This ensures timer continues even after screen navigation
  Future<void> _loadNextGenerationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimeKey = 'next_generation_time_${widget.parentId}';
      final savedTimeString = prefs.getString(savedTimeKey);
      
      if (savedTimeString != null) {
        // Load saved time
        _nextGenerationTime = DateTime.parse(savedTimeString);
        final now = DateTime.now();
        
        print('⏰ [RecommendationsTab] Loaded saved time: $_nextGenerationTime');
        print('   Current time: $now');
        print('   Remaining: ${_nextGenerationTime!.difference(now).inMinutes} minutes');
        
        // If saved time has passed, generate immediately
        if (_nextGenerationTime!.isBefore(now) || _nextGenerationTime!.isAtSameMomentAs(now)) {
          print('⏰ [RecommendationsTab] Saved time has passed, generating now...');
          _nextGenerationTime = null; // Will be set after generation
          _checkAndGenerate();
        }
      } else {
        // First time - check Firebase for last generation time
        final lastGenTime = await _recommendationService.getLastGenerationTimestamp(widget.parentId);
        final now = DateTime.now();
        
        if (lastGenTime != null) {
          // Calculate next generation time: lastGenTime + 6 hours
          _nextGenerationTime = lastGenTime.add(const Duration(hours: 6));
          print('⏰ [RecommendationsTab] Using Firebase timestamp - next generation at: $_nextGenerationTime');
        } else {
          // First time ever - set next generation to 6 hours from now
          _nextGenerationTime = now.add(const Duration(hours: 6));
          print('⏰ [RecommendationsTab] First time setup - next generation at: $_nextGenerationTime');
        }
        
        // Save to SharedPreferences
        await _saveNextGenerationTime();
      }
      
      setState(() {});
    } catch (e) {
      print('❌ [RecommendationsTab] Error loading timer: $e');
      // Fallback: set to 6 hours from now
      _nextGenerationTime = DateTime.now().add(const Duration(hours: 6));
      await _saveNextGenerationTime();
      setState(() {});
    }
  }

  /// Save next generation time to SharedPreferences
  /// This ensures timer persists across screen navigation
  Future<void> _saveNextGenerationTime() async {
    try {
      if (_nextGenerationTime == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final savedTimeKey = 'next_generation_time_${widget.parentId}';
      await prefs.setString(savedTimeKey, _nextGenerationTime!.toIso8601String());
      
      print('💾 [RecommendationsTab] Saved next generation time: $_nextGenerationTime');
    } catch (e) {
      print('❌ [RecommendationsTab] Error saving timer: $e');
    }
  }

  /// Calculate remaining time based on current time and next generation time
  /// This is REAL-TIME calculation - always accurate regardless of app state
  Duration _calculateRemainingTime() {
    if (_nextGenerationTime == null) {
      return const Duration(hours: 6); // Default fallback
    }
    
    final now = DateTime.now();
    final remaining = _nextGenerationTime!.difference(now);
    
    // If time has passed, return zero
    if (remaining.isNegative) {
      return Duration.zero;
    }
    
    return remaining;
  }

  /// Start countdown timer - updates UI every second
  /// But calculation is always based on REAL current time
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final remaining = _calculateRemainingTime();
      
      if (remaining.inSeconds <= 0) {
        // Time reached - generate recommendations
        _checkAndGenerate();
      } else {
        // Update UI with current remaining time
        setState(() {});
      }
    });
  }

  /// Check if time to generate and trigger generation
  Future<void> _checkAndGenerate() async {
    if (_isGenerating) return;
    
    _isGenerating = true;
    setState(() {});

    try {
      print('🤖 [RecommendationsTab] Auto-generating recommendations...');
      await _generateRecommendations();
      
      // After generation, set next generation time to 6 hours from now
      _nextGenerationTime = DateTime.now().add(const Duration(hours: 6));
      print('⏰ [RecommendationsTab] Next generation scheduled at: $_nextGenerationTime');
      
      // Save to SharedPreferences so timer persists
      await _saveNextGenerationTime();
      
      setState(() {});
    } catch (e) {
      print('❌ [RecommendationsTab] Error in auto-generation: $e');
    } finally {
      _isGenerating = false;
      setState(() {});
    }
  }

  /// Get all recommendations for all children
  Stream<List<RecommendationModel>> _getAllRecommendationsStream() {
    // Listen to children collection changes and fetch recommendations
    return _firestore
        .collection('parents')
        .doc(widget.parentId)
        .collection('children')
        .snapshots()
        .asyncMap((childrenSnapshot) async {
      print('📱 [RecommendationsTab] Children snapshot received: ${childrenSnapshot.docs.length} children');
      
      if (childrenSnapshot.docs.isEmpty) {
        print('⚠️ [RecommendationsTab] No children found, returning empty list');
        return <RecommendationModel>[];
      }

      // Get recommendations from all children
      final allRecommendations = <RecommendationModel>[];
      
      for (final childDoc in childrenSnapshot.docs) {
        final childId = childDoc.id;
        try {
          final recommendationsSnapshot = await _firestore
              .collection('parents')
              .doc(widget.parentId)
              .collection('children')
              .doc(childId)
              .collection('recommendations')
              .orderBy('timestamp', descending: true)
              .get();

          print('📱 [RecommendationsTab] Found ${recommendationsSnapshot.docs.length} recommendations for child $childId');
          
          allRecommendations.addAll(
            recommendationsSnapshot.docs
                .map((doc) {
                  try {
                    return RecommendationModel.fromFirestore(doc);
                  } catch (e) {
                    print('❌ [RecommendationsTab] Error parsing recommendation ${doc.id}: $e');
                    return null;
                  }
                })
                .where((rec) => rec != null)
                .cast<RecommendationModel>()
                .toList(),
          );
        } catch (e) {
          print('⚠️ [RecommendationsTab] Error fetching recommendations for child $childId: $e');
          // Continue with other children even if one fails
        }
      }

      // Sort by timestamp
      allRecommendations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('✅ [RecommendationsTab] Total recommendations: ${allRecommendations.length}');
      return allRecommendations;
    }).handleError((error) {
      print('❌ [RecommendationsTab] Stream error: $error');
      return <RecommendationModel>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Countdown Timer
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkCyan.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule,
                color: AppColors.darkCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Next AI Recommendations in: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  _formatDuration(_calculateRemainingTime()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCyan,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isGenerating) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCyan),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
        ),

        // Recommendations List
        Expanded(
          child: StreamBuilder<List<RecommendationModel>>(
            stream: _getAllRecommendationsStream(),
            initialData: <RecommendationModel>[], // Start with empty list
            builder: (context, snapshot) {
              // Show loading only on initial load
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Use empty list if no data yet
              final allRecommendations = snapshot.data ?? [];
              
              print('📱 [RecommendationsTab] Building UI with ${allRecommendations.length} recommendations');
              
              // Filter by status
              final filteredRecommendations = _filterStatus == 'all'
                  ? allRecommendations
                  : allRecommendations.where((rec) {
                      return rec.status.value == _filterStatus;
                    }).toList();

              if (filteredRecommendations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _filterStatus == 'all'
                            ? 'No AI recommendations available yet'
                            : 'No ${_filterStatus} recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_filterStatus == 'all')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'AI recommendations will be generated automatically every 6 hours based on your child\'s activity data.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Just refresh the list, don't regenerate
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  itemCount: filteredRecommendations.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final recommendation = filteredRecommendations[index];
                    return _buildRecommendationCard(recommendation);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: AppColors.darkCyan.withOpacity(0.2),
      checkmarkColor: AppColors.darkCyan,
    );
  }

  Widget _buildRecommendationCard(RecommendationModel recommendation) {
    final statusColor = _getStatusColor(recommendation.status);
    final statusIcon = _getStatusIcon(recommendation.status);
    final dateTime = DateFormat('MMM d, y • h:mm a').format(recommendation.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: recommendation.status == RecommendationStatus.pending ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.darkCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation for ${recommendation.childName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              recommendation.status.value.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Approve/Reject buttons (only for pending)
                if (recommendation.status == RecommendationStatus.pending)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                        onPressed: () => _approveRecommendation(recommendation),
                        tooltip: 'Approve',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                        onPressed: () => _rejectRecommendation(recommendation),
                        tooltip: 'Reject',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Recommendation Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recommendation.recommendation,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Footer
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  dateTime,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.grey[600],
                  onPressed: () => _deleteRecommendation(recommendation),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RecommendationStatus status) {
    switch (status) {
      case RecommendationStatus.pending:
        return Colors.orange;
      case RecommendationStatus.approved:
        return Colors.green;
      case RecommendationStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(RecommendationStatus status) {
    switch (status) {
      case RecommendationStatus.pending:
        return Icons.pending;
      case RecommendationStatus.approved:
        return Icons.check_circle;
      case RecommendationStatus.rejected:
        return Icons.cancel;
    }
  }

  Future<void> _generateRecommendations() async {
    try {
      await _recommendationService.generateRecommendationsForAllChildren(widget.parentId);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ New AI recommendations generated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generating recommendations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Format duration to HH:MM:SS
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _approveRecommendation(RecommendationModel recommendation) async {
    try {
      await _recommendationService.approveRecommendation(
        parentId: recommendation.parentId,
        childId: recommendation.childId,
        recommendationId: recommendation.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Recommendation approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRecommendation(RecommendationModel recommendation) async {
    try {
      await _recommendationService.rejectRecommendation(
        parentId: recommendation.parentId,
        childId: recommendation.childId,
        recommendationId: recommendation.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Recommendation rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecommendation(RecommendationModel recommendation) async {
    try {
      await _recommendationService.deleteRecommendation(
        parentId: recommendation.parentId,
        childId: recommendation.childId,
        recommendationId: recommendation.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Recommendation deleted'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

