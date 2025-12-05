import 'package:equatable/equatable.dart';
import '../../data/models/visited_url.dart';

abstract class UrlTrackingState extends Equatable {
  const UrlTrackingState();

  @override
  List<Object?> get props => [];
}

class UrlTrackingInitial extends UrlTrackingState {
  const UrlTrackingInitial();
}

class UrlTrackingLoading extends UrlTrackingState {
  const UrlTrackingLoading();
}

class UrlTrackingLoaded extends UrlTrackingState {
  final List<VisitedUrl> visitedUrls;
  final bool isTrackingActive;
  final bool hasPermissions;

  const UrlTrackingLoaded({
    required this.visitedUrls,
    this.isTrackingActive = false,
    this.hasPermissions = false,
  });

  UrlTrackingLoaded copyWith({
    List<VisitedUrl>? visitedUrls,
    bool? isTrackingActive,
    bool? hasPermissions,
  }) {
    return UrlTrackingLoaded(
      visitedUrls: visitedUrls ?? this.visitedUrls,
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      hasPermissions: hasPermissions ?? this.hasPermissions,
    );
  }

  @override
  List<Object?> get props => [visitedUrls, isTrackingActive, hasPermissions];
}

class UrlTrackingError extends UrlTrackingState {
  final String message;

  const UrlTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}

class PermissionsDenied extends UrlTrackingState {
  const PermissionsDenied();
}

class PermissionsGranted extends UrlTrackingState {
  const PermissionsGranted();
}
