import '../repositories/url_tracking_repository.dart';

class StopUrlTracking {
  final UrlTrackingRepository repository;

  StopUrlTracking(this.repository);

  Future<void> call() async {
    await repository.stopTracking();
  }
}
