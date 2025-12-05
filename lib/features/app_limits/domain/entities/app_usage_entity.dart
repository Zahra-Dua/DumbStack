class AppUsageEntity {
  final String packageName;
  final String appName;
  final String iconPath;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;
  final int dailyLimitMinutes;
  final int usedMinutes;
  final bool isRestricted;

  const AppUsageEntity({
    required this.packageName,
    required this.appName,
    required this.iconPath,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
    this.dailyLimitMinutes = 0,
    this.usedMinutes = 0,
    this.isRestricted = false,
  });

  AppUsageEntity copyWith({
    String? packageName,
    String? appName,
    String? iconPath,
    Duration? totalTimeInForeground,
    DateTime? lastTimeUsed,
    int? dailyLimitMinutes,
    int? usedMinutes,
    bool? isRestricted,
  }) {
    return AppUsageEntity(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconPath: iconPath ?? this.iconPath,
      totalTimeInForeground: totalTimeInForeground ?? this.totalTimeInForeground,
      lastTimeUsed: lastTimeUsed ?? this.lastTimeUsed,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      isRestricted: isRestricted ?? this.isRestricted,
    );
  }

  bool get isLimitReached => usedMinutes >= dailyLimitMinutes && dailyLimitMinutes > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUsageEntity && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() {
    return 'AppUsageEntity(packageName: $packageName, appName: $appName, dailyLimitMinutes: $dailyLimitMinutes, usedMinutes: $usedMinutes, isRestricted: $isRestricted)';
  }
}
