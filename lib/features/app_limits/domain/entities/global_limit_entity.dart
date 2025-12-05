class GlobalLimitEntity {
  final int dailyLimitMinutes;
  final int usedMinutes;
  final DateTime lastUpdated;
  final bool isActive;

  const GlobalLimitEntity({
    required this.dailyLimitMinutes,
    this.usedMinutes = 0,
    required this.lastUpdated,
    this.isActive = true,
  });

  GlobalLimitEntity copyWith({
    int? dailyLimitMinutes,
    int? usedMinutes,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return GlobalLimitEntity(
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
    return other is GlobalLimitEntity && other.dailyLimitMinutes == dailyLimitMinutes;
  }

  @override
  int get hashCode => dailyLimitMinutes.hashCode;

  @override
  String toString() {
    return 'GlobalLimitEntity(dailyLimitMinutes: $dailyLimitMinutes, usedMinutes: $usedMinutes, isActive: $isActive)';
  }
}
