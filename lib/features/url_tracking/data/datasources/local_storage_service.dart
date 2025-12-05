import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visited_url.dart';

class LocalStorageService {
  static const String _visitedUrlsKey = 'visited_urls_v3';
  static const String _lastCleanupKey = 'last_cleanup_time';

  // Add URL to storage with proper management
  Future<void> addVisitedUrl(VisitedUrl url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      // Add new URL at the beginning (most recent first)
      urlsJson.insert(0, jsonEncode(url.toJson()));
      
      // Keep only last 1000 URLs to prevent storage bloat
      if (urlsJson.length > 1000) {
        urlsJson.removeRange(1000, urlsJson.length);
      }
      
      await prefs.setStringList(_visitedUrlsKey, urlsJson);
      print('💾 LocalStorage: URL saved to storage: ${url.url}');
    } catch (e) {
      print('❌ LocalStorage: Error saving URL: $e');
    }
  }

  // Get all visited URLs from storage
  Future<List<VisitedUrl>> getVisitedUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      final urls = urlsJson.map((e) {
        try {
          return VisitedUrl.fromJson(jsonDecode(e));
        } catch (e) {
          print('⚠️ LocalStorage: Error parsing URL: $e');
          return null;
        }
      }).where((url) => url != null).cast<VisitedUrl>().toList();
      
      print('📊 LocalStorage: Loaded ${urls.length} URLs from storage');
      return urls;
    } catch (e) {
      print('❌ LocalStorage: Error loading URLs: $e');
      return [];
    }
  }

  // Get recent URLs (last 24 hours)
  Future<List<VisitedUrl>> getRecentUrls({int hours = 24}) async {
    try {
      final allUrls = await getVisitedUrls();
      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
      
      final recentUrls = allUrls.where((url) => 
        url.visitedAt.isAfter(cutoffTime)
      ).toList();
      
      print('📊 LocalStorage: Found ${recentUrls.length} recent URLs (last $hours hours)');
      return recentUrls;
    } catch (e) {
      print('❌ LocalStorage: Error loading recent URLs: $e');
      return [];
    }
  }

  // Update URL in storage
  Future<void> updateVisitedUrl(VisitedUrl updatedUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      for (int i = 0; i < urlsJson.length; i++) {
        try {
          final url = VisitedUrl.fromJson(jsonDecode(urlsJson[i]));
          if (url.id == updatedUrl.id) {
            urlsJson[i] = jsonEncode(updatedUrl.toJson());
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      await prefs.setStringList(_visitedUrlsKey, urlsJson);
      print('💾 LocalStorage: URL updated in storage: ${updatedUrl.url}');
    } catch (e) {
      print('❌ LocalStorage: Error updating URL: $e');
    }
  }

  // Delete URL from storage
  Future<void> deleteVisitedUrl(String urlId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      urlsJson.removeWhere((urlJson) {
        try {
          final url = VisitedUrl.fromJson(jsonDecode(urlJson));
          return url.id == urlId;
        } catch (e) {
          return false;
        }
      });
      
      await prefs.setStringList(_visitedUrlsKey, urlsJson);
      print('🗑️ LocalStorage: URL deleted from storage: $urlId');
    } catch (e) {
      print('❌ LocalStorage: Error deleting URL: $e');
    }
  }

  // Clear all URLs
  Future<void> clearAllUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_visitedUrlsKey);
      await prefs.remove(_lastCleanupKey);
      print('🗑️ LocalStorage: All URLs cleared from storage');
    } catch (e) {
      print('❌ LocalStorage: Error clearing URLs: $e');
    }
  }

  // Clear old URLs (older than specified days)
  Future<void> clearOldUrls({int days = 7}) async {
    try {
      final allUrls = await getVisitedUrls();
      final cutoffTime = DateTime.now().subtract(Duration(days: days));
      
      final recentUrls = allUrls.where((url) => 
        url.visitedAt.isAfter(cutoffTime)
      ).toList();
      
      final prefs = await SharedPreferences.getInstance();
      final urlsJson = recentUrls.map((url) => jsonEncode(url.toJson())).toList();
      await prefs.setStringList(_visitedUrlsKey, urlsJson);
      
      print('🧹 LocalStorage: Cleared old URLs, kept ${recentUrls.length} recent URLs');
    } catch (e) {
      print('❌ LocalStorage: Error clearing old URLs: $e');
    }
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final allUrls = await getVisitedUrls();
      final now = DateTime.now();
      
      final todayUrls = allUrls.where((url) => 
        url.visitedAt.day == now.day && 
        url.visitedAt.month == now.month && 
        url.visitedAt.year == now.year
      ).length;
      
      final weekUrls = allUrls.where((url) => 
        url.visitedAt.isAfter(now.subtract(Duration(days: 7)))
      ).length;
      
      return {
        'totalUrls': allUrls.length,
        'todayUrls': todayUrls,
        'weekUrls': weekUrls,
        'lastUrl': allUrls.isNotEmpty ? allUrls.first.url : null,
        'lastVisitTime': allUrls.isNotEmpty ? allUrls.first.visitedAt.toIso8601String() : null,
      };
    } catch (e) {
      print('❌ LocalStorage: Error getting storage stats: $e');
      return {};
    }
  }

  // Legacy method for compatibility
  Future<void> clear() async {
    await clearAllUrls();
  }
}


