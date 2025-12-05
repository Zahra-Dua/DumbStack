import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'child_url_blocker_service.dart';
import '../../presentation/widgets/blocked_url_warning_page.dart';

/// Interceptor for WebView that blocks URLs in real-time
class ChildBrowserInterceptor {
  final ChildUrlBlockerService blockerService;

  ChildBrowserInterceptor(this.blockerService);

  /// Create a NavigationDelegate that blocks URLs
  NavigationDelegate createBlockingNavigationDelegate({
    required BuildContext context,
    Function(String)? onUrlBlocked,
  }) {
    return NavigationDelegate(
      onNavigationRequest: (NavigationRequest request) {
        // Check if URL should be blocked
        if (blockerService.shouldBlockUrl(request.url)) {
          final reason = blockerService.getBlockReason(request.url);
          
          // Show warning page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlockedUrlWarningPage(
                blockedUrl: request.url,
                reason: reason,
              ),
            ),
          );
          
          // Notify callback
          onUrlBlocked?.call(request.url);
          
          // Prevent navigation
          return NavigationDecision.prevent;
        }
        
        // Allow navigation
        return NavigationDecision.navigate;
      },
      onPageStarted: (String url) {
        // Check again when page starts loading
        if (blockerService.shouldBlockUrl(url)) {
          // This will be handled by onNavigationRequest, but double-check
          return;
        }
      },
      onUrlChange: (UrlChange change) {
        if (change.url != null) {
          if (blockerService.shouldBlockUrl(change.url!)) {
            final reason = blockerService.getBlockReason(change.url!);
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlockedUrlWarningPage(
                  blockedUrl: change.url!,
                  reason: reason,
                ),
              ),
            );
          }
        }
      },
    );
  }

  /// Intercept URL before launching
  Future<bool> shouldAllowUrl(String url) async {
    return !blockerService.shouldBlockUrl(url);
  }
}

