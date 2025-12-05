import 'package:equatable/equatable.dart';
import '../../data/models/visited_url.dart';

abstract class UrlTrackingEvent extends Equatable {
  const UrlTrackingEvent();

  @override
  List<Object?> get props => [];
}

class LoadVisitedUrls extends UrlTrackingEvent {
  const LoadVisitedUrls();
}

class AddVisitedUrl extends UrlTrackingEvent {
  final VisitedUrl url;

  const AddVisitedUrl(this.url);

  @override
  List<Object?> get props => [url];
}

class UpdateUrlBlockStatus extends UrlTrackingEvent {
  final String urlId;
  final bool isBlocked;

  const UpdateUrlBlockStatus({
    required this.urlId,
    required this.isBlocked,
  });

  @override
  List<Object?> get props => [urlId, isBlocked];
}

class DeleteVisitedUrl extends UrlTrackingEvent {
  final String urlId;

  const DeleteVisitedUrl(this.urlId);

  @override
  List<Object?> get props => [urlId];
}

class StartUrlTracking extends UrlTrackingEvent {
  const StartUrlTracking();
}

class StopUrlTracking extends UrlTrackingEvent {
  const StopUrlTracking();
}

class CheckPermissions extends UrlTrackingEvent {
  const CheckPermissions();
}

class RequestPermissions extends UrlTrackingEvent {
  const RequestPermissions();
}
