import 'dart:io';
import '../models/installed_package.dart';
import '../models/installation_result.dart';
import '../models/package_info.dart';
import '../models/package_source.dart';
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

  /// Update a specific package
  Future<InstallationResult> updatePackage(String packageName, {String source = 'apt'}) async {
    final startTime = DateTime.now();
    
    try {
      ProcessResult result;
      
      switch (source) {
        case 'snap':
          result = await Process.run('pkexec', ['snap', 'refresh', packageName]);
          break;
        case 'flatpak':
          result = await Process.run('pkexec', ['flatpak', 'update', '-y', packageName]);
          break;
        case 'apt':
        default:
          // Update package list first
          await Process.run('pkexec', ['apt', 'update']);
          result = await Process.run('pkexec', ['apt', 'install', '--only-upgrade', '-y', packageName]);
          break;
      }
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.exitCode != 0 ? result.stderr.toString() : '',
        packageName: packageName,
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'Update failed: $e',
        packageName: packageName,
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Update all packages
  Future<InstallationResult> updateAllPackages({String source = 'apt'}) async {
    final startTime = DateTime.now();
    
    try {
      ProcessResult result;
      
      switch (source) {
        case 'snap':
          result = await Process.run('pkexec', ['snap', 'refresh']);
          break;
        case 'flatpak':
          result = await Process.run('pkexec', ['flatpak', 'update', '-y']);
          break;
        case 'apt':
        default:
          // Update package list first
          await Process.run('pkexec', ['apt', 'update']);
          result = await Process.run('pkexec', ['apt', 'upgrade', '-y']);
          break;
      }
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.exitCode != 0 ? result.stderr.toString() : '',
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'System update failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Get detailed information about a package
  Future<PackageInfo?> getPackageDetails(String packageName, {String source = 'apt'}) async {
    try {
      switch (source) {
        case 'snap':
          return await _getSnapPackageDetails(packageName);
        case 'flatpak':
          return await _getFlatpakPackageDetails(packageName);
        case 'apt':
        default:
          return await _getAptPackageDetails(packageName);
      }
    } catch (e) {
      return null;
    }
  }

  Future<PackageInfo?> _getAptPackageDetails(String packageName) async {
    try {
      final result = await Process.run('apt', ['show', packageName]);
      
      if (result.exitCode == 0) {
        return PackageInfo.fromAptShow(result.stdout.toString());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PackageInfo?> _getSnapPackageDetails(String packageName) async {
    try {
      final result = await Process.run('snap', ['info', packageName]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        
        String name = packageName;
        String version = '';
        String description = '';
        String? homepage;
        String? maintainer;
        
        for (var line in lines) {
          if (line.startsWith('name:')) {
            name = line.substring(5).trim();
          } else if (line.startsWith('version:')) {
            version = line.substring(8).trim();
          } else if (line.startsWith('summary:')) {
            description = line.substring(8).trim();
          } else if (line.startsWith('website:')) {
            homepage = line.substring(8).trim();
          } else if (line.startsWith('publisher:')) {
            maintainer = line.substring(10).trim();
          }
        }
        
        return PackageInfo(
          name: name,
          version: version,
          description: description,
          homepage: homepage,
          maintainer: maintainer,
          source: PackageSource.snap,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PackageInfo?> _getFlatpakPackageDetails(String packageName) async {
    try {
      final result = await Process.run('flatpak', ['info', packageName]);
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        
        String name = packageName;
        String version = '';
        String description = '';
        
        for (var line in lines) {
          if (line.contains('ID:')) {
            name = line.split(':').last.trim();
          } else if (line.contains('Version:')) {
            version = line.split(':').last.trim();
          } else if (line.contains('Description:')) {
            description = line.split(':').last.trim();
          }
        }
        
        return PackageInfo(
          name: name,
          version: version,
          description: description,
          source: PackageSource.flatpak,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check for available updates
  Future<List<String>> getAvailableUpdates({String source = 'apt'}) async {
    try {
      switch (source) {
        case 'snap':
          return await _getSnapUpdates();
        case 'flatpak':
          return await _getFlatpakUpdates();
        case 'apt':
        default:
          return await _getAptUpdates();
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getAptUpdates() async {
    try {
      // Update package list
      await Process.run('apt', ['update']);
      
      final result = await Process.run('apt', ['list', '--upgradable']);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final updates = <String>[];
        
        for (var line in lines) {
          if (line.contains('[upgradable from:')) {
            final packageName = line.split('/').first.trim();
            if (packageName.isNotEmpty && packageName != 'Listing...') {
              updates.add(packageName);
            }
          }
        }
        
        return updates;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getSnapUpdates() async {
    try {
      final result = await Process.run('snap', ['refresh', '--list']);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final updates = <String>[];
        
        for (var line in lines) {
          if (line.trim().isNotEmpty && !line.startsWith('Name')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.isNotEmpty) {
              updates.add(parts[0]);
            }
          }
        }
        
        return updates;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getFlatpakUpdates() async {
    try {
      final result = await Process.run('flatpak', ['remote-ls', '--updates']);
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final updates = <String>[];
        
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            final parts = line.split('\t');
            if (parts.length >= 2) {
              updates.add(parts[1].trim());
            }
          }
        }
        
        return updates;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Clean package cache and remove orphaned packages
  Future<InstallationResult> cleanSystem({String source = 'apt'}) async {
    final startTime = DateTime.now();
    
    try {
      ProcessResult result;
      
      switch (source) {
        case 'snap':
          // Snap doesn't have a traditional clean command
          result = ProcessResult(0, 0, 'Snap packages are automatically cleaned', '');
          break;
        case 'flatpak':
          result = await Process.run('pkexec', ['flatpak', 'uninstall', '--unused', '-y']);
          break;
        case 'apt':
        default:
          // Clean package cache and remove orphaned packages
          final cleanResult = await Process.run('pkexec', ['apt', 'clean']);
          final autoremoveResult = await Process.run('pkexec', ['apt', 'autoremove', '-y']);
          
          result = ProcessResult(
            0,
            cleanResult.exitCode == 0 && autoremoveResult.exitCode == 0 ? 0 : 1,
            '${cleanResult.stdout}\n${autoremoveResult.stdout}',
            '${cleanResult.stderr}\n${autoremoveResult.stderr}',
          );
          break;
      }
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.exitCode != 0 ? result.stderr.toString() : '',
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'System cleanup failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }
}
