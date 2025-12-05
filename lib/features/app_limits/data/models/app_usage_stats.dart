class AppUsageStats {
  final String packageName;
  final String appName;
  final String iconPath;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;
  final Duration foregroundTime;
  final int launchCount;

  const AppUsageStats({
    required this.packageName,
    required this.appName,
    required this.iconPath,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
    this.foregroundTime = Duration.zero,
    this.launchCount = 0,
  });

  AppUsageStats copyWith({
    String? packageName,
    String? appName,
    String? iconPath,
    Duration? totalTimeInForeground,
    DateTime? lastTimeUsed,
    Duration? foregroundTime,
    int? launchCount,
  }) {
    return AppUsageStats(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconPath: iconPath ?? this.iconPath,
      totalTimeInForeground: totalTimeInForeground ?? this.totalTimeInForeground,
      lastTimeUsed: lastTimeUsed ?? this.lastTimeUsed,
      foregroundTime: foregroundTime ?? this.foregroundTime,
      launchCount: launchCount ?? this.launchCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUsageStats && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;

  // Helper methods
  String get formattedUsageTime {
    final hours = totalTimeInForeground.inHours;
    final minutes = totalTimeInForeground.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get formattedLastUsed {
    final now = DateTime.now();
    final difference = now.difference(lastTimeUsed);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  double getUsagePercentage(int dailyLimitMinutes) {
    if (dailyLimitMinutes <= 0) return 0.0;
    final usedMinutes = totalTimeInForeground.inMinutes;
    return (usedMinutes / dailyLimitMinutes).clamp(0.0, 1.0);
  }

  factory AppUsageStats.fromMap(Map<String, dynamic> map) {
    return AppUsageStats(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      iconPath: map['iconPath'] ?? '',
      totalTimeInForeground: Duration(milliseconds: map['totalTimeInForeground'] ?? 0),
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(map['lastTimeUsed'] ?? 0),
      foregroundTime: Duration(milliseconds: map['foregroundTime'] ?? 0),
      launchCount: map['launchCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconPath': iconPath,
      'totalTimeInForeground': totalTimeInForeground.inMilliseconds,
      'lastTimeUsed': lastTimeUsed.millisecondsSinceEpoch,
      'foregroundTime': foregroundTime.inMilliseconds,
      'launchCount': launchCount,
    };
  }

  @override
  String toString() {
    return 'AppUsageStats(packageName: $packageName, appName: $appName, totalTimeInForeground: $totalTimeInForeground)';
  }
}
