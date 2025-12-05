import 'package:equatable/equatable.dart';

class BrowserInfo extends Equatable {
  final String packageName;
  final String appName;
  final bool isInstalled;

  const BrowserInfo({
    required this.packageName,
    required this.appName,
    required this.isInstalled,
  });

  @override
  List<Object?> get props => [packageName, appName, isInstalled];
}

// Common browser package names
class BrowserPackages {
  static const String chrome = 'com.android.chrome';
  static const String firefox = 'org.mozilla.firefox';
  static const String edge = 'com.microsoft.emmx';
  static const String opera = 'com.opera.browser';
  static const String samsungBrowser = 'com.sec.android.app.sbrowser';
  static const String ucBrowser = 'com.UCMobile.intl';
  static const String brave = 'com.brave.browser';
  
  static const List<String> allBrowsers = [
    chrome,
    firefox,
    edge,
    opera,
    samsungBrowser,
    ucBrowser,
    brave,
  ];
}