import 'package:equatable/equatable.dart';

class VisitedUrl extends Equatable {
  final String id;
  final String url;
  final String title;
  final DateTime visitedAt;
  final bool isBlocked;
  final String packageName; // Browser package name (e.g., com.android.chrome)

  const VisitedUrl({
    required this.id,
    required this.url,
    required this.title,
    required this.visitedAt,
    this.isBlocked = false,
    required this.packageName,
  });

  VisitedUrl copyWith({
    String? id,
    String? url,
    String? title,
    DateTime? visitedAt,
    bool? isBlocked,
    String? packageName,
  }) {
    return VisitedUrl(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      visitedAt: visitedAt ?? this.visitedAt,
      isBlocked: isBlocked ?? this.isBlocked,
      packageName: packageName ?? this.packageName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'visitedAt': visitedAt.toIso8601String(),
      'isBlocked': isBlocked,
      'packageName': packageName,
    };
  }

  factory VisitedUrl.fromJson(Map<String, dynamic> json) {
    return VisitedUrl(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      isBlocked: json['isBlocked'] as bool? ?? false,
      packageName: json['packageName'] as String,
    );
  }

  @override
  List<Object?> get props => [id, url, title, visitedAt, isBlocked, packageName];
}