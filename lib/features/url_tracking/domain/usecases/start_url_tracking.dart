import '../repositories/url_tracking_repository.dart';

class StartUrlTracking {
  final UrlTrackingRepository repository;

  StartUrlTracking(this.repository);

  Future<void> call() async {
    await repository.startTracking();
  }
}
