import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../url_tracking/data/models/visited_url.dart';

class LocalStorageService {
  static const String _visitedUrlsKey = 'visited_urls';
  static const String _appLimitsKey = 'app_daily_limits';
  static const String _globalLimitKey = 'global_daily_limit';

  Future<void> setAppDailyLimit(String packageName, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> limits = _readJsonMap(prefs.getString(_appLimitsKey));
    limits[packageName] = {
      'dailyLimitMinutes': minutes,
      'usedMinutes': 0,
      'lastReset': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_appLimitsKey, jsonEncode(limits));
  }

  Future<Map<String, dynamic>> getAppDailyLimits() async {
    final prefs = await SharedPreferences.getInstance();
    return _readJsonMap(prefs.getString(_appLimitsKey));
  }

  Future<void> updateAppUsage(String packageName, int usedMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> limits = _readJsonMap(prefs.getString(_appLimitsKey));
    if (limits.containsKey(packageName)) {
      final item = Map<String, dynamic>.from(limits[packageName]);
      item['usedMinutes'] = usedMinutes;
      item['lastReset'] = item['lastReset'] ?? DateTime.now().toIso8601String();
      limits[packageName] = item;
      await prefs.setString(_appLimitsKey, jsonEncode(limits));
    }
  }

  Future<void> clearAppDailyLimit(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> limits = _readJsonMap(prefs.getString(_appLimitsKey));
    limits.remove(packageName);
    await prefs.setString(_appLimitsKey, jsonEncode(limits));
  }

  Future<void> setGlobalDailyLimit(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final limit = {
      'dailyLimitMinutes': minutes,
      'usedMinutes': 0,
      'lastReset': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_globalLimitKey, jsonEncode(limit));
  }

  Future<Map<String, dynamic>?> getGlobalDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final limitStr = prefs.getString(_globalLimitKey);
    if (limitStr == null) return null;
    return _readJsonMap(limitStr);
  }

  Future<void> clearGlobalDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_globalLimitKey);
  }

  Future<void> resetDailyIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> limits = _readJsonMap(prefs.getString(_appLimitsKey));
    bool changed = false;
    final now = DateTime.now();
    limits.forEach((pkg, data) {
      final item = Map<String, dynamic>.from(data);
      final lastResetIso = item['lastReset'] as String?;
      final lastReset = lastResetIso != null ? DateTime.tryParse(lastResetIso) : null;
      if (lastReset == null || lastReset.day != now.day || lastReset.month != now.month || lastReset.year != now.year) {
        item['usedMinutes'] = 0;
        item['lastReset'] = now.toIso8601String();
        limits[pkg] = item;
        changed = true;
      }
    });
    if (changed) {
      await prefs.setString(_appLimitsKey, jsonEncode(limits));
    }
  }

  Future<void> setGlobalDailyLimitMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final data = {
      'dailyLimitMinutes': minutes,
      'usedMinutes': 0,
      'lastReset': now.toIso8601String(),
    };
    await prefs.setString(_globalLimitKey, jsonEncode(data));
  }


  Future<void> updateGlobalUsedMinutes(int usedMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final data = _readJsonMap(prefs.getString(_globalLimitKey));
    if (data.isNotEmpty) {
      data['usedMinutes'] = usedMinutes;
      if (data['lastReset'] == null) {
        data['lastReset'] = DateTime.now().toIso8601String();
      }
      await prefs.setString(_globalLimitKey, jsonEncode(data));
    }
  }

  Map<String, dynamic> _readJsonMap(String? value) {
    if (value == null || value.isEmpty) return <String, dynamic>{};
    try {
      final parsed = jsonDecode(value);
      if (parsed is Map<String, dynamic>) return parsed;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> addVisitedUrl(VisitedUrl url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      // Add new URL to the beginning of the list
      urlsJson.insert(0, jsonEncode(url.toJson()));
      
      // Keep only the last 100 URLs to prevent storage bloat
      if (urlsJson.length > 100) {
        urlsJson.removeRange(100, urlsJson.length);
      }
      
      await prefs.setStringList(_visitedUrlsKey, urlsJson);
    } catch (e) {
      throw Exception('Failed to add visited URL: $e');
    }
  }

  Future<List<VisitedUrl>> getVisitedUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      return urlsJson
          .map((json) => VisitedUrl.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      throw Exception('Failed to get visited URLs: $e');
    }
  }

  Future<void> updateUrlBlockStatus(String urlId, bool isBlocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      final updatedUrlsJson = urlsJson.map((json) {
        final urlData = jsonDecode(json);
        if (urlData['id'] == urlId) {
          urlData['isBlocked'] = isBlocked;
        }
        return jsonEncode(urlData);
      }).toList();
      
      await prefs.setStringList(_visitedUrlsKey, updatedUrlsJson);
    } catch (e) {
      throw Exception('Failed to update URL block status: $e');
    }
  }

  Future<void> deleteVisitedUrl(String urlId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> urlsJson = prefs.getStringList(_visitedUrlsKey) ?? [];
      
      final updatedUrlsJson = urlsJson.where((json) {
        final urlData = jsonDecode(json);
        return urlData['id'] != urlId;
      }).toList();
      
      await prefs.setStringList(_visitedUrlsKey, updatedUrlsJson);
    } catch (e) {
      throw Exception('Failed to delete visited URL: $e');
    }
  }

  Stream<List<VisitedUrl>> getVisitedUrlsStream() async* {
    while (true) {
      yield await getVisitedUrls();
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<List<VisitedUrl>> getBlockedUrls() async {
    try {
      final urls = await getVisitedUrls();
      return urls.where((url) => url.isBlocked).toList();
    } catch (e) {
      throw Exception('Failed to get blocked URLs: $e');
    }
  }

  Future<List<VisitedUrl>> getUrlsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final urls = await getVisitedUrls();
      return urls.where((url) {
        return url.visitedAt.isAfter(startDate) && url.visitedAt.isBefore(endDate);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get URLs by date range: $e');
    }
  }
}
