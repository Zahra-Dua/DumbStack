class AppLimitEntity {
  final String packageName;
  final int dailyLimitMinutes;
  final int usedMinutes;
  final DateTime lastUpdated;
  final bool isActive;

  const AppLimitEntity({
    required this.packageName,
    required this.dailyLimitMinutes,
    this.usedMinutes = 0,
    required this.lastUpdated,
    this.isActive = true,
  });

  AppLimitEntity copyWith({
    String? packageName,
    int? dailyLimitMinutes,
    int? usedMinutes,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return AppLimitEntity(
      packageName: packageName ?? this.packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isLimitReached => usedMinutes >= dailyLimitMinutes && dailyLimitMinutes > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppLimitEntity && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() {
    return 'AppLimitEntity(packageName: $packageName, dailyLimitMinutes: $dailyLimitMinutes, usedMinutes: $usedMinutes, isActive: $isActive)';
  }
}
