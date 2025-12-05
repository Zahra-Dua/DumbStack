import 'package:flutter/services.dart';

class VpnTrackingService {
  static const MethodChannel _channel = MethodChannel('vpn_tracker');

  static Future<void> startVpn() async {
    try {
      await _channel.invokeMethod('startVpn');
    } catch (e) {
      print('⚠️ Failed to start VPN: $e');
    }
  }

  static void listenDomains(Function(String domain) onDomain) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDomainDetected') {
        final domain = call.arguments as String;
        if (domain.isNotEmpty) {
          onDomain(domain);
        }
      }
    });
  }
}


