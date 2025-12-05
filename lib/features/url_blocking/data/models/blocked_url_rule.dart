import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a blocked URL rule
class BlockedUrlRule {
  final String id;
  final String url; // Full URL or domain pattern
  final String? domain; // Extracted domain for faster matching
  final String childId;
  final String parentId;
  final DateTime blockedAt;
  final String? reason; // Why it was blocked
  final bool isActive; // Can be temporarily disabled
  final BlockType blockType; // Exact URL, domain, or pattern

  BlockedUrlRule({
    required this.id,
    required this.url,
    this.domain,
    required this.childId,
    required this.parentId,
    required this.blockedAt,
    this.reason,
    this.isActive = true,
    this.blockType = BlockType.domain,
  });

  /// Create from Firestore document (recommended - uses doc.id as fallback)
  factory BlockedUrlRule.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return BlockedUrlRule(
      id: json['id'] as String? ?? doc.id, // Use doc.id as fallback
      url: json['url'] as String,
      domain: json['domain'] as String?,
      childId: json['childId'] as String,
      parentId: json['parentId'] as String,
      blockedAt: (json['blockedAt'] as Timestamp).toDate(),
      reason: json['reason'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      blockType: BlockType.values.firstWhere(
        (e) => e.toString() == 'BlockType.${json['blockType']}',
        orElse: () => BlockType.domain,
      ),
    );
  }

  /// Create from JSON map (for backward compatibility)
  factory BlockedUrlRule.fromJson(Map<String, dynamic> json) {
    return BlockedUrlRule(
      id: json['id'] as String,
      url: json['url'] as String,
      domain: json['domain'] as String?,
      childId: json['childId'] as String,
      parentId: json['parentId'] as String,
      blockedAt: (json['blockedAt'] as Timestamp).toDate(),
      reason: json['reason'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      blockType: BlockType.values.firstWhere(
        (e) => e.toString() == 'BlockType.${json['blockType']}',
        orElse: () => BlockType.domain,
      ),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'domain': domain ?? _extractDomain(url),
      'childId': childId,
      'parentId': parentId,
      'blockedAt': Timestamp.fromDate(blockedAt),
      'reason': reason,
      'isActive': isActive,
      'blockType': blockType.toString().split('.').last,
    };
  }

  /// Extract domain from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      // If URL parsing fails, try simple extraction
      final regex = RegExp(r'https?://([^/]+)');
      final match = regex.firstMatch(url);
      return match?.group(1) ?? url;
    }
  }

  /// Check if a given URL matches this block rule
  /// Improved with subdomain handling, case-insensitive matching, and pattern support
  bool matches(String urlToCheck) {
    if (!isActive) return false;

    final check = urlToCheck.trim().toLowerCase();
    final ruleUrlLower = url.toLowerCase();
    
    // Cache domain extraction to avoid repeated parsing
    final ruleDomain = (domain ?? _extractDomain(url)).toLowerCase();

    try {
      final checkUri = Uri.parse(check);
      final checkHost = checkUri.host.toLowerCase();

      switch (blockType) {
        case BlockType.exact:
          // Exact match - normalize URLs (remove trailing slashes, fragments)
          final normalizedCheck = _normalizeUrl(check);
          final normalizedRule = _normalizeUrl(ruleUrlLower);
          return normalizedCheck == normalizedRule;

        case BlockType.domain:
          // Match exact domain or subdomain (e.g., sub.example.com matches example.com)
          if (checkHost == ruleDomain) return true;
          if (checkHost.endsWith('.$ruleDomain')) return true;
          return false;

        case BlockType.pattern:
          // If ruleUrlLower looks like a RegExp, treat it as such
          try {
            final regex = RegExp(ruleUrlLower, caseSensitive: false);
            return regex.hasMatch(check) || regex.hasMatch(checkHost);
          } catch (e) {
            // Not a valid regex, use simple contains
            return check.contains(ruleUrlLower) || checkHost.contains(ruleUrlLower);
          }
      }
    } catch (e) {
      // Fallback to simple string matching if URI parsing fails
      return check.contains(ruleUrlLower);
    }
  }

  /// Normalize URL for exact matching (remove trailing slashes, fragments, query params)
  String _normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path.replaceAll(RegExp(r'/$'), '')}';
    } catch (e) {
      return url.replaceAll(RegExp(r'/$'), '').split('#').first.split('?').first;
    }
  }
}

enum BlockType {
  exact, // Exact URL match
  domain, // Block entire domain
  pattern, // Pattern matching (contains)
}

