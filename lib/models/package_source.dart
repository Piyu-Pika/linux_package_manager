enum PackageSource {
  local,
  apt,
  snap,
  flatpak,
  appImage,
  github,
  custom,
}

extension PackageSourceExtension on PackageSource {
  String get displayName {
    switch (this) {
      case PackageSource.local:
        return 'Local File';
      case PackageSource.apt:
        return 'APT Repository';
      case PackageSource.snap:
        return 'Snap Store';
      case PackageSource.flatpak:
        return 'Flatpak';
      case PackageSource.appImage:
        return 'AppImage';
      case PackageSource.github:
        return 'GitHub Releases';
      case PackageSource.custom:
        return 'Custom URL';
    }
  }

  String get icon {
    switch (this) {
      case PackageSource.local:
        return '📁';
      case PackageSource.apt:
        return '📦';
      case PackageSource.snap:
        return '🔷';
      case PackageSource.flatpak:
        return '📱';
      case PackageSource.appImage:
        return '🖥️';
      case PackageSource.github:
        return '🐙';
      case PackageSource.custom:
        return '🌐';
    }
  }
}