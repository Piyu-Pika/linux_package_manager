import 'dart:io';

class SystemDetector {
  static Future<String> getDistribution() async {
    try {
      // Try to read /etc/os-release
      final osReleaseFile = File('/etc/os-release');
      if (await osReleaseFile.exists()) {
        final content = await osReleaseFile.readAsString();
        final lines = content.split('\n');
        
        for (var line in lines) {
          if (line.startsWith('ID=')) {
            return line.substring(3).replaceAll('"', '').toLowerCase();
          }
        }
      }
      
      // Fallback to lsb_release
      final result = await Process.run('lsb_release', ['-si']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim().toLowerCase();
      }
      
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<List<String>> getAvailablePackageManagers() async {
    final managers = <String>[];
    
    // Check for common package managers
    final commands = {
      'apt': 'apt',
      'yum': 'yum',
      'dnf': 'dnf',
      'pacman': 'pacman',
      'zypper': 'zypper',
      'snap': 'snap',
      'flatpak': 'flatpak',
    };
    
    for (var entry in commands.entries) {
      try {
        final result = await Process.run('which', [entry.value]);
        if (result.exitCode == 0) {
          managers.add(entry.key);
        }
      } catch (e) {
        // Command not found
      }
    }
    
    return managers;
  }

  static Future<bool> hasCommand(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getArchitecture() async {
    try {
      final result = await Process.run('uname', ['-m']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}