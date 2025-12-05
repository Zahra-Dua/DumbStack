import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/services/child_url_blocker_service.dart';
import 'blocked_url_warning_page.dart';

/// WebView wrapper that intercepts and blocks URLs
class BlockedWebViewWrapper extends StatefulWidget {
  final String initialUrl;
  final ChildUrlBlockerService blockerService;

  const BlockedWebViewWrapper({
    super.key,
    required this.initialUrl,
    required this.blockerService,
  });

  @override
  State<BlockedWebViewWrapper> createState() => _BlockedWebViewWrapperState();
}

class _BlockedWebViewWrapperState extends State<BlockedWebViewWrapper> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });

            // Check if URL should be blocked
            if (widget.blockerService.shouldBlockUrl(url)) {
              _handleBlockedUrl(url);
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercept navigation requests
            if (widget.blockerService.shouldBlockUrl(request.url)) {
              _handleBlockedUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              if (widget.blockerService.shouldBlockUrl(change.url!)) {
                _handleBlockedUrl(change.url!);
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _handleBlockedUrl(String url) {
    final reason = widget.blockerService.getBlockReason(url);
    
    // Update loading state
    setState(() {
      _isLoading = false;
    });
    
    // Show warning page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BlockedUrlWarningPage(
          blockedUrl: url,
          reason: reason,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

