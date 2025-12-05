import '../repositories/url_tracking_repository.dart';

class DeleteVisitedUrl {
  final UrlTrackingRepository repository;

  DeleteVisitedUrl(this.repository);

  Future<void> call(String urlId) async {
    await repository.deleteVisitedUrl(urlId);
  }
}
