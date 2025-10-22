import 'package_source.dart';

class PackageInfo {
  final String name;
  final String version;
  final String description;
  final String? homepage;
  final String? maintainer;
  final int? size;
  final List<String> dependencies;
  final PackageSource source;
  final String? downloadUrl;
  final String? iconUrl;
  final List<String> screenshots;
  final double? rating;
  final int? downloads;
  final DateTime? lastUpdated;

  PackageInfo({
    required this.name,
    required this.version,
    required this.description,
    this.homepage,
    this.maintainer,
    this.size,
    this.dependencies = const [],
    required this.source,
    this.downloadUrl,
    this.iconUrl,
    this.screenshots = const [],
    this.rating,
    this.downloads,
    this.lastUpdated,
  });

  factory PackageInfo.fromAptShow(String output) {
    final lines = output.split('\n');
    String name = '';
    String version = '';
    String description = '';
    String? homepage;
    String? maintainer;
    int? size;
    List<String> dependencies = [];

    for (var line in lines) {
      if (line.startsWith('Package: ')) {
        name = line.substring(9).trim();
      } else if (line.startsWith('Version: ')) {
        version = line.substring(9).trim();
      } else if (line.startsWith('Description: ')) {
        description = line.substring(13).trim();
      } else if (line.startsWith('Homepage: ')) {
        homepage = line.substring(10).trim();
      } else if (line.startsWith('Maintainer: ')) {
        maintainer = line.substring(12).trim();
      } else if (line.startsWith('Installed-Size: ')) {
        size = int.tryParse(line.substring(16).trim());
      } else if (line.startsWith('Depends: ')) {
        final depString = line.substring(9).trim();
        dependencies = depString.split(',').map((e) => e.trim()).toList();
      }
    }

    return PackageInfo(
      name: name,
      version: version,
      description: description,
      homepage: homepage,
      maintainer: maintainer,
      size: size,
      dependencies: dependencies,
      source: PackageSource.apt,
    );
  }

  String get formattedSize {
    if (size == null) return 'Unknown';
    if (size! < 1024) return '${size}KB';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)}MB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)}GB';
  }
}