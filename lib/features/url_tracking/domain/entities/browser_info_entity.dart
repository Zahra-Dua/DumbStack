class BrowserInfoEntity {
  final String name;
  final String version;
  final String packageName;

  const BrowserInfoEntity({
    required this.name,
    required this.version,
    required this.packageName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrowserInfoEntity &&
        other.name == name &&
        other.version == version &&
        other.packageName == packageName;
  }

  @override
  int get hashCode => name.hashCode ^ version.hashCode ^ packageName.hashCode;

  @override
  String toString() {
    return 'BrowserInfoEntity(name: $name, version: $version, packageName: $packageName)';
  }
}
