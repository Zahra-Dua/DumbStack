import '../entities/visited_url_entity.dart';

abstract class UrlTrackingRepository {
  Stream<VisitedUrlEntity> get urlStream;
  
  Future<List<VisitedUrlEntity>> getVisitedUrls();
  Future<void> addVisitedUrl(VisitedUrlEntity url);
  Future<void> updateVisitedUrl(VisitedUrlEntity url);
  Future<void> deleteVisitedUrl(String urlId);
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<bool> hasPermissions();
  Future<void> requestPermissions();
}
