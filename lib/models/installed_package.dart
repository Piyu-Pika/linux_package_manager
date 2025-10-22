enum PackageType {
  application,
  library,
  development,
  system,
  game,
  multimedia,
  network,
  utility,
  unknown,
}

extension PackageTypeExtension on PackageType {
  String get displayName {
    switch (this) {
      case PackageType.application:
        return 'Application';
      case PackageType.library:
        return 'Library';
      case PackageType.development:
        return 'Development';
      case PackageType.system:
        return 'System';
      case PackageType.game:
        return 'Game';
      case PackageType.multimedia:
        return 'Multimedia';
      case PackageType.network:
        return 'Network';
      case PackageType.utility:
        return 'Utility';
      case PackageType.unknown:
        return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case PackageType.application:
        return '📱';
      case PackageType.library:
        return '📚';
      case PackageType.development:
        return '⚙️';
      case PackageType.system:
        return '🔧';
      case PackageType.game:
        return '🎮';
      case PackageType.multimedia:
        return '🎵';
      case PackageType.network:
        return '🌐';
      case PackageType.utility:
        return '🛠️';
      case PackageType.unknown:
        return '📦';
    }
  }
}

class InstalledPackage {
  final String name;
  final String version;
  final String description;
  final bool isSystemPackage;
  final PackageType type;
  final String source;

  InstalledPackage({
    required this.name,
    required this.version,
    required this.description,
    this.isSystemPackage = false,
    this.type = PackageType.unknown,
    this.source = 'apt',
  });

  factory InstalledPackage.fromDpkgLine(String line) {
    // Format: "install ok installed PACKAGE VERSION DESCRIPTION"
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 6) {
      return InstalledPackage(
        name: 'unknown',
        version: '',
        description: '',
      );
    }

    // Skip the status parts (install ok installed) and get package info
    final packageName = parts[3];
    final version = parts[4];
    final description = parts.length > 5 ? parts.sublist(5).join(' ') : '';

    return InstalledPackage(
      name: packageName,
      version: version,
      description: description,
      isSystemPackage: _isSystemPackage(packageName),
      type: _getPackageType(packageName, description),
      source: 'apt',
    );
  }

  static bool _isSystemPackage(String packageName) {
    const systemPrefixes = [
      'lib',
      'linux-',
      'systemd',
      'ubuntu-',
      'debian-',
      'gnome-shell',
      'kde-',
      'x11-',
      'xorg-',
      'gtk',
      'qt',
      'glibc',
      'base-',
      'init',
      'kernel',
      'firmware',
      'driver',
    ];

    const systemPackages = [
      'bash',
      'coreutils',
      'util-linux',
      'systemd',
      'udev',
      'dbus',
      'NetworkManager',
      'pulseaudio',
      'alsa-utils',
    ];

    return systemPrefixes.any((prefix) => packageName.startsWith(prefix)) ||
           systemPackages.contains(packageName);
  }

  static PackageType _getPackageType(String packageName, String description) {
    final lowerName = packageName.toLowerCase();
    final lowerDesc = description.toLowerCase();

    // Games
    if (lowerName.contains('game') || 
        lowerDesc.contains('game') || 
        lowerDesc.contains('puzzle') ||
        lowerDesc.contains('arcade')) {
      return PackageType.game;
    }

    // Development tools
    if (lowerName.contains('dev') || 
        lowerName.contains('gcc') ||
        lowerName.contains('make') ||
        lowerName.contains('cmake') ||
        lowerName.contains('git') ||
        lowerName.contains('python') ||
        lowerName.contains('nodejs') ||
        lowerName.contains('compiler') ||
        lowerDesc.contains('development') ||
        lowerDesc.contains('compiler') ||
        lowerDesc.contains('programming')) {
      return PackageType.development;
    }

    // Libraries
    if (lowerName.startsWith('lib') || 
        lowerDesc.contains('library') ||
        lowerDesc.contains('shared library')) {
      return PackageType.library;
    }

    // Multimedia
    if (lowerName.contains('audio') ||
        lowerName.contains('video') ||
        lowerName.contains('media') ||
        lowerName.contains('ffmpeg') ||
        lowerName.contains('vlc') ||
        lowerName.contains('music') ||
        lowerDesc.contains('multimedia') ||
        lowerDesc.contains('audio') ||
        lowerDesc.contains('video')) {
      return PackageType.multimedia;
    }

    // Network tools
    if (lowerName.contains('network') ||
        lowerName.contains('net') ||
        lowerName.contains('curl') ||
        lowerName.contains('wget') ||
        lowerName.contains('ssh') ||
        lowerName.contains('ftp') ||
        lowerDesc.contains('network') ||
        lowerDesc.contains('internet')) {
      return PackageType.network;
    }

    // System packages
    if (_isSystemPackage(packageName)) {
      return PackageType.system;
    }

    // Utilities
    if (lowerName.contains('util') ||
        lowerName.contains('tool') ||
        lowerDesc.contains('utility') ||
        lowerDesc.contains('tool')) {
      return PackageType.utility;
    }

    // Applications (GUI programs)
    if (lowerDesc.contains('application') ||
        lowerDesc.contains('editor') ||
        lowerDesc.contains('browser') ||
        lowerDesc.contains('client') ||
        lowerName.contains('firefox') ||
        lowerName.contains('chrome') ||
        lowerName.contains('code') ||
        lowerName.contains('office')) {
      return PackageType.application;
    }

    return PackageType.unknown;
  }
}
