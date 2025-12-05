import '../entities/visited_url_entity.dart';
import '../repositories/url_tracking_repository.dart';

class GetVisitedUrls {
  final UrlTrackingRepository repository;

  GetVisitedUrls(this.repository);

  Future<List<VisitedUrlEntity>> call() async {
    return await repository.getVisitedUrls();
  }
}
