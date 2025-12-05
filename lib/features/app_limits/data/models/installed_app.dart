class InstalledApp {
  final String packageName;
  final String appName;
  final String? iconPath;
  final String? versionName;
  final int? versionCode;
  final bool isSystemApp;
  final DateTime installTime;
  final DateTime lastUpdateTime;

  InstalledApp({
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.versionName,
    this.versionCode,
    required this.isSystemApp,
    required this.installTime,
    required this.lastUpdateTime,
  });

  factory InstalledApp.fromMap(Map<String, dynamic> map) {
    return InstalledApp(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      iconPath: map['iconPath'],
      versionName: map['versionName'],
      versionCode: map['versionCode'],
      isSystemApp: map['isSystemApp'] ?? false,
      installTime: DateTime.fromMillisecondsSinceEpoch(map['installTime'] ?? 0),
      lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(map['lastUpdateTime'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconPath': iconPath,
      'versionName': versionName,
      'versionCode': versionCode,
      'isSystemApp': isSystemApp,
      'installTime': installTime.millisecondsSinceEpoch,
      'lastUpdateTime': lastUpdateTime.millisecondsSinceEpoch,
    };
  }
}
