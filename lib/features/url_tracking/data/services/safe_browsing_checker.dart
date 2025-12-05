import 'dart:convert';
import 'package:http/http.dart' as http;

class SafeBrowsingChecker {
  final String apiKey;
  final String clientId;
  final String clientVersion;

  final Map<String, _CacheEntry> _cache = {};

  SafeBrowsingChecker({
    required this.apiKey,
    this.clientId = 'safenest',
    this.clientVersion = '1.0',
  });

  Future<List<String>> checkUrl(String url) async {
    final normalized = _normalizeForCache(url);
    final now = DateTime.now();
    final cached = _cache[normalized];
    if (cached != null && now.isBefore(cached.expiry)) {
      return cached.threats;
    }

    final uri = Uri.parse('https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey');
    final body = {
      'client': {'clientId': clientId, 'clientVersion': clientVersion},
      'threatInfo': {
        'threatTypes': [
          'MALWARE',
          'SOCIAL_ENGINEERING',
          'UNWANTED_SOFTWARE',
          'POTENTIALLY_HARMFUL_APPLICATION'
        ],
        'platformTypes': ['ANY_PLATFORM'],
        'threatEntryTypes': ['URL'],
        'threatEntries': [
          {'url': url}
        ]
      }
    };

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        final jsonResp = jsonDecode(resp.body) as Map<String, dynamic>;
        final matches = jsonResp['matches'] as List<dynamic>?;
        final threats = <String>[];
        if (matches != null) {
          for (final m in matches) {
            final type = m['threatType'] as String?;
            if (type != null) threats.add(type);
          }
        }
        final ttl = threats.isNotEmpty ? const Duration(hours: 1) : const Duration(days: 1);
        _cache[normalized] = _CacheEntry(threats: threats, expiry: now.add(ttl));
        return threats;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  String _normalizeForCache(String url) {
    try {
      final u = Uri.parse(url);
      return '${u.host.toLowerCase()}${u.path}';
    } catch (_) {
      return url.toLowerCase();
    }
  }
}

class _CacheEntry {
  final List<String> threats;
  final DateTime expiry;
  _CacheEntry({required this.threats, required this.expiry});
}
