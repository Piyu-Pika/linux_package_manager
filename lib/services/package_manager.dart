import 'dart:io';
import '../models/installed_package.dart';
import '../models/installation_result.dart';
import 'system_detector.dart';

class PackageManager {
  Future<List<InstalledPackage>> getInstalledPackages() async {
    final packages = <InstalledPackage>[];
    final availableManagers = await SystemDetector.getAvailablePackageManagers();
    
    // Get APT packages
    if (availableManagers.contains('apt')) {
      packages.addAll(await _getAptPackages());
    }
    
    // Get Snap packages
    if (availableManagers.contains('snap')) {
      packages.addAll(await _getSnapPackages());
    }
    
    // Get Flatpak packages
    if (availableManagers.contains('flatpak')) {
      packages.addAll(await _getFlatpakPackages());
    }
    
    // Sort packages by name
    packages.sort((a, b) => a.name.compareTo(b.name));
    return packages;
  }

  Future<List<InstalledPackage>> _getAptPackages() async {
    try {
      final result = await Process.run('dpkg-query', [
        '-W',
        r'-f=${Status} ${Package} ${Version} ${Description}\n',
      ]);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final packages = <InstalledPackage>[];
        
        for (var line in lines) {
          if (line.trim().isEmpty) continue;
          if (!line.startsWith('install ok installed')) continue;
          
          try {
            final package = InstalledPackage.fromDpkgLine(line);
            if (package.name != 'unknown') {
              packages.add(package);
            }
          } catch (e) {
            // Skip malformed lines
            continue;
          }
        }
        
        return packages;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<InstalledPackage>> _getSnapPackages() async {
    try {
      final result = await Process.run('snap', ['list']);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final packages = <InstalledPackage>[];
        
        // Skip header line
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          
          final parts = line.split(RegExp(r'\s+'));
          if (parts.isNotEmpty && parts.length >= 3) {
            packages.add(InstalledPackage(
              name: parts[0],
              version: parts[1],
              description: 'Snap package',
              source: 'snap',
              type: PackageType.application,
            ));
          }
        }
        
        return packages;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<InstalledPackage>> _getFlatpakPackages() async {
    try {
      final result = await Process.run('flatpak', ['list', '--app']);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final packages = <InstalledPackage>[];
        
        for (var line in lines) {
          if (line.trim().isEmpty) continue;
          
          final parts = line.split('\t');
          if (parts.length >= 2) {
            packages.add(InstalledPackage(
              name: parts[1].trim(), // Application ID
              version: parts.length > 2 ? parts[2].trim() : 'latest',
              description: parts.isNotEmpty ? parts[0].trim() : 'Flatpak application',
              source: 'flatpak',
              type: PackageType.application,
            ));
          }
        }
        
        return packages;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<InstallationResult> uninstallPackage(String packageName, {String source = 'apt'}) async {
    try {
      ProcessResult result;
      
      switch (source) {
        case 'snap':
          result = await Process.run('pkexec', ['snap', 'remove', packageName]);
          break;
        case 'flatpak':
          result = await Process.run('pkexec', ['flatpak', 'uninstall', '-y', packageName]);
          break;
        case 'apt':
        default:
          result = await Process.run('pkexec', ['apt-get', 'remove', '-y', packageName]);
          break;
      }
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.exitCode != 0 ? result.stderr.toString() : '',
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'Uninstall failed: $e',
      );
    }
  }

  Future<InstallationResult> purgePackage(String packageName, {String source = 'apt'}) async {
    try {
      ProcessResult result;
      
      switch (source) {
        case 'snap':
          // Snap doesn't have purge, just remove
          result = await Process.run('pkexec', ['snap', 'remove', '--purge', packageName]);
          break;
        case 'flatpak':
          // Flatpak doesn't have purge, just uninstall
          result = await Process.run('pkexec', ['flatpak', 'uninstall', '-y', '--delete-data', packageName]);
          break;
        case 'apt':
        default:
          result = await Process.run('pkexec', ['apt-get', 'purge', '-y', packageName]);
          break;
      }
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.exitCode != 0 ? result.stderr.toString() : '',
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'Purge failed: $e',
      );
    }
  }
}
