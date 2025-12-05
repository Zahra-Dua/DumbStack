import '../entities/visited_url_entity.dart';
import '../repositories/url_tracking_repository.dart';

class UpdateVisitedUrl {
  final UrlTrackingRepository repository;

  UpdateVisitedUrl(this.repository);

  Future<void> call(VisitedUrlEntity url) async {
    await repository.updateVisitedUrl(url);
  }
}
