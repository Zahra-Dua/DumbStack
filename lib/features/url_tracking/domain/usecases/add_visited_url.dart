import '../entities/visited_url_entity.dart';
import '../repositories/url_tracking_repository.dart';

class AddVisitedUrl {
  final UrlTrackingRepository repository;

  AddVisitedUrl(this.repository);

  Future<void> call(VisitedUrlEntity url) async {
    await repository.addVisitedUrl(url);
  }
}
