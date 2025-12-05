import '../../domain/entities/visited_url_entity.dart';
import '../../domain/repositories/url_tracking_repository.dart';
import '../datasources/url_tracking_service.dart';
import '../models/visited_url.dart';

class UrlTrackingRepositoryImpl implements UrlTrackingRepository {
  final UrlTrackingService _urlTrackingService;

  UrlTrackingRepositoryImpl(this._urlTrackingService);

  @override
  Stream<VisitedUrlEntity> get urlStream => _urlTrackingService.urlStream.map((url) => VisitedUrlEntity(
    id: url.id,
    url: url.url,
    title: url.title,
    visitedAt: url.visitedAt,
    isBlocked: url.isBlocked,
    browserInfo: url.packageName,
  ));

  @override
  Future<List<VisitedUrlEntity>> getVisitedUrls() async {
    final urls = await _urlTrackingService.loadVisitedUrls();
    return urls.map((url) => VisitedUrlEntity(
      id: url.id,
      url: url.url,
      title: url.title,
      visitedAt: url.visitedAt,
      isBlocked: url.isBlocked,
      browserInfo: url.packageName,
    )).toList();
  }

  @override
  Future<void> addVisitedUrl(VisitedUrlEntity url) async {
    final visitedUrl = VisitedUrl(
      id: url.id,
      url: url.url,
      title: url.title,
      visitedAt: url.visitedAt,
      isBlocked: url.isBlocked,
      packageName: url.browserInfo ?? '',
    );
    await _urlTrackingService.localStorage.addVisitedUrl(visitedUrl);
  }

  @override
  Future<void> updateVisitedUrl(VisitedUrlEntity url) async {
    final visitedUrl = VisitedUrl(
      id: url.id,
      url: url.url,
      title: url.title,
      visitedAt: url.visitedAt,
      isBlocked: url.isBlocked,
      packageName: url.browserInfo ?? '',
    );
    await _urlTrackingService.localStorage.updateVisitedUrl(visitedUrl);
  }

  @override
  Future<void> deleteVisitedUrl(String urlId) async {
    await _urlTrackingService.localStorage.deleteVisitedUrl(urlId);
  }

  @override
  Future<void> startTracking() async {
    await _urlTrackingService.startTracking();
  }

  @override
  Future<void> stopTracking() async {
    await _urlTrackingService.stopTracking();
  }

  @override
  Future<bool> hasPermissions() async {
    return await _urlTrackingService.hasUsageStatsPermission() ||
           await _urlTrackingService.hasAccessibilityPermission();
  }

  @override
  Future<void> requestPermissions() async {
    await _urlTrackingService.requestAccessibilityPermission();
    await _urlTrackingService.requestUsageStatsPermission();
  }
}
