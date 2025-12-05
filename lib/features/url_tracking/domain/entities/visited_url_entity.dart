class VisitedUrlEntity {
  final String id;
  final String url;
  final String title;
  final DateTime visitedAt;
  final bool isBlocked;
  final String? browserInfo;

  const VisitedUrlEntity({
    required this.id,
    required this.url,
    required this.title,
    required this.visitedAt,
    this.isBlocked = false,
    this.browserInfo,
  });

  VisitedUrlEntity copyWith({
    String? id,
    String? url,
    String? title,
    DateTime? visitedAt,
    bool? isBlocked,
    String? browserInfo,
  }) {
    return VisitedUrlEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      visitedAt: visitedAt ?? this.visitedAt,
      isBlocked: isBlocked ?? this.isBlocked,
      browserInfo: browserInfo ?? this.browserInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisitedUrlEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VisitedUrlEntity(id: $id, url: $url, title: $title, visitedAt: $visitedAt, isBlocked: $isBlocked)';
  }
}
