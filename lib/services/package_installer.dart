import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../models/installation_result.dart';
import '../models/package_info.dart';
import '../models/package_source.dart';
import '../config/api_config.dart';
import 'system_detector.dart';
import 'security_scanner_service.dart';
import 'scan_report_manager.dart';

class PackageInstaller {
  final SecurityScannerService _securityScanner = SecurityScannerService();
  final ScanReportManager _scanReportManager = ScanReportManager();

  Future<InstallationResult> installFromUrl(String url, {String? fileName}) async {
    final startTime = DateTime.now();
    
    try {
      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return InstallationResult(
          success: false,
          output: '',
          error: 'Failed to download: HTTP ${response.statusCode}',
          installTime: DateTime.now().difference(startTime),
        );
      }

      // Create temp file
      final tempDir = Directory.systemTemp.createTempSync('pkg_download_');
      final downloadedFileName = fileName ?? path.basename(url);
      final tempFile = File(path.join(tempDir.path, downloadedFileName));
      
      await tempFile.writeAsBytes(response.bodyBytes);
      
      // Install the downloaded file
      final result = await installPackage(tempFile.path);
      
      // Cleanup
      await tempDir.delete(recursive: true);
      
      return InstallationResult(
        success: result.success,
        output: 'Downloaded from: $url\n\n${result.output}',
        error: result.error,
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'Download failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> installFromPackageInfo(PackageInfo package) async {
    final startTime = DateTime.now();
    
    switch (package.source) {
      case PackageSource.apt:
        return await _installAptPackage(package.name, startTime);
      case PackageSource.snap:
        return await _installSnapPackage(package.name, startTime);
      case PackageSource.flatpak:
        return await _installFlatpakPackage(package.name, startTime);
      case PackageSource.github:
        if (package.downloadUrl != null) {
          return await installFromUrl(package.downloadUrl!, fileName: '${package.name}-${package.version}');
        }
        break;
      default:
        break;
    }
    
    return InstallationResult(
      success: false,
      output: '',
      error: 'Unsupported package source: ${package.source}',
      packageName: package.name,
      installTime: DateTime.now().difference(startTime),
    );
  }

  Future<InstallationResult> _installAptPackage(String packageName, DateTime startTime) async {
    try {
      // Update package list first
      await Process.run('pkexec', ['apt', 'update']);
      
      // Install package
      final result = await Process.run('pkexec', ['apt', 'install', '-y', packageName]);
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: 'Package list updated\n\n${result.stdout}',
        error: result.exitCode != 0 ? result.stderr.toString() : '',
        packageName: packageName,
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'APT installation failed: $e',
        packageName: packageName,
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> _installSnapPackage(String packageName, DateTime startTime) async {
    try {
      final result = await Process.run('pkexec', ['snap', 'install', packageName]);
      
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
        error: 'Snap installation failed: $e',
        packageName: packageName,
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> _installFlatpakPackage(String packageName, DateTime startTime) async {
    try {
      final result = await Process.run('pkexec', ['flatpak', 'install', '-y', 'flathub', packageName]);
      
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
        error: 'Flatpak installation failed: $e',
        packageName: packageName,
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> installPackage(String filePath, {bool skipVirusScan = false}) async {
    final startTime = DateTime.now();
    final file = File(filePath);
    
    if (!await file.exists()) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'File does not exist',
        installTime: DateTime.now().difference(startTime),
      );
    }

    // Perform VirusTotal scan if enabled and not skipped
    if (!skipVirusScan && await ApiConfig.isVirusScanningEnabled()) {
      final scanResult = await _performVirusScan(filePath);
      if (scanResult != null && !scanResult.success) {
        return scanResult;
      }
    }

    final extension = path.extension(filePath).toLowerCase();
    final fileName = path.basename(filePath);

    try {
      if (extension == '.deb') {
        return await _installDebPackage(filePath, startTime);
      } else if (fileName.endsWith('.tar.gz') || 
                 fileName.endsWith('.tar.xz') || 
                 extension == '.gz' || 
                 extension == '.xz') {
        return await _installTarPackage(filePath, startTime);
      } else if (extension == '.appimage') {
        return await _installAppImage(filePath, startTime);
      } else if (extension == '.rpm') {
        return await _installRpmPackage(filePath, startTime);
      } else if (extension == '.pkg') {
        return await _installPkgPackage(filePath, startTime);
      } else {
        return InstallationResult(
          success: false,
          output: '',
          error: 'Unsupported file format: $extension',
          installTime: DateTime.now().difference(startTime),
        );
      }
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: e.toString(),
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> _installDebPackage(String filePath, DateTime startTime) async {
    final StringBuffer output = StringBuffer();
    
    try {
      output.writeln('Installing .deb package with dpkg...');
      final dpkgResult = await Process.run('pkexec', ['dpkg', '-i', filePath]);
      
      output.writeln(dpkgResult.stdout);
      if (dpkgResult.stderr.toString().isNotEmpty) {
        output.writeln('Errors: ${dpkgResult.stderr}');
      }

      output.writeln('\nFixing dependencies with apt...');
      final aptResult = await Process.run('pkexec', ['apt-get', 'install', '-f', '-y']);
      output.writeln(aptResult.stdout);
      
      return InstallationResult(
        success: dpkgResult.exitCode == 0,
        output: output.toString(),
        error: dpkgResult.exitCode != 0 ? dpkgResult.stderr.toString() : '',
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: output.toString(),
        error: 'DEB installation failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> _installRpmPackage(String filePath, DateTime startTime) async {
    final StringBuffer output = StringBuffer();
    
    try {
      // Check if we have rpm or dnf/yum
      final hasRpm = await SystemDetector.hasCommand('rpm');
      final hasDnf = await SystemDetector.hasCommand('dnf');
      final hasYum = await SystemDetector.hasCommand('yum');
      
      if (!hasRpm && !hasDnf && !hasYum) {
        return InstallationResult(
          success: false,
          output: '',
          error: 'No RPM package manager found (rpm, dnf, or yum required)',
          installTime: DateTime.now().difference(startTime),
        );
      }
      
      output.writeln('Installing .rpm package...');
      
      ProcessResult result;
      if (hasDnf) {
        result = await Process.run('pkexec', ['dnf', 'install', '-y', filePath]);
      } else if (hasYum) {
        result = await Process.run('pkexec', ['yum', 'install', '-y', filePath]);
      } else {
        result = await Process.run('pkexec', ['rpm', '-i', filePath]);
      }
      
      output.writeln(result.stdout);
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: output.toString(),
        error: result.exitCode != 0 ? result.stderr.toString() : '',
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: output.toString(),
        error: 'RPM installation failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> _installPkgPackage(String filePath, DateTime startTime) async {
    final StringBuffer output = StringBuffer();
    
    try {
      // Check if we have pacman (Arch Linux)
      final hasPacman = await SystemDetector.hasCommand('pacman');
      
      if (!hasPacman) {
        return InstallationResult(
          success: false,
          output: '',
          error: 'Pacman not found (required for .pkg files)',
          installTime: DateTime.now().difference(startTime),
        );
      }
      
      output.writeln('Installing .pkg package with pacman...');
      final result = await Process.run('pkexec', ['pacman', '-U', '--noconfirm', filePath]);
      
      output.writeln(result.stdout);
      
      return InstallationResult(
        success: result.exitCode == 0,
        output: output.toString(),
        error: result.exitCode != 0 ? result.stderr.toString() : '',
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: output.toString(),
        error: 'PKG installation failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> _installTarPackage(String filePath, DateTime startTime) async {
    final StringBuffer output = StringBuffer();
    
    try {
      final tempDir = Directory.systemTemp.createTempSync('pkg_install_');
      output.writeln('Extracting to: ${tempDir.path}');
      
      final extractResult = await Process.run('tar', ['-xf', filePath, '-C', tempDir.path]);
      
      if (extractResult.exitCode != 0) {
        return InstallationResult(
          success: false,
          output: output.toString(),
          error: 'Failed to extract: ${extractResult.stderr}',
          installTime: DateTime.now().difference(startTime),
        );
      }
      
      output.writeln('Extraction completed');
      
      // Look for install script
      final installScripts = ['install.sh', 'setup.sh', 'install', 'configure'];
      File? installScript;
      
      for (var scriptName in installScripts) {
        final scriptFile = File(path.join(tempDir.path, scriptName));
        if (await scriptFile.exists()) {
          installScript = scriptFile;
          break;
        }
      }
      
      if (installScript != null) {
        output.writeln('\nFound install script: ${path.basename(installScript.path)}');
        await Process.run('chmod', ['+x', installScript.path]);
        
        output.writeln('Running install script...');
        final installResult = await Process.run(
          'pkexec',
          ['sh', installScript.path],
          workingDirectory: tempDir.path,
        );
        
        output.writeln(installResult.stdout);
        
        return InstallationResult(
          success: installResult.exitCode == 0,
          output: output.toString(),
          error: installResult.exitCode != 0 ? installResult.stderr.toString() : '',
          installTime: DateTime.now().difference(startTime),
        );
      } else {
        output.writeln('\nNo install script found. Files extracted to: ${tempDir.path}');
        
        return InstallationResult(
          success: true,
          output: output.toString(),
          error: 'Manual installation may be required',
          installTime: DateTime.now().difference(startTime),
        );
      }
    } catch (e) {
      return InstallationResult(
        success: false,
        output: output.toString(),
        error: 'TAR installation failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  Future<InstallationResult> _installAppImage(String filePath, DateTime startTime) async {
    final StringBuffer output = StringBuffer();
    
    try {
      output.writeln('Making AppImage executable...');
      await Process.run('chmod', ['+x', filePath]);
      
      final homeDir = Platform.environment['HOME'] ?? '';
      final appsDir = Directory('$homeDir/.local/share/applications');
      
      if (!await appsDir.exists()) {
        await appsDir.create(recursive: true);
      }
      
      final fileName = path.basename(filePath);
      final destPath = path.join(homeDir, '.local', 'bin', fileName);
      final destDir = Directory(path.dirname(destPath));
      
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      
      output.writeln('Copying AppImage to: $destPath');
      await File(filePath).copy(destPath);
      await Process.run('chmod', ['+x', destPath]);
      
      // Try to extract desktop entry
      try {
        final extractResult = await Process.run(destPath, ['--appimage-extract-and-run', '--appimage-help']);
        if (extractResult.exitCode == 0) {
          output.writeln('AppImage supports desktop integration');
        }
      } catch (e) {
        // Ignore extraction errors
      }
      
      output.writeln('\nAppImage installed successfully!');
      output.writeln('Location: $destPath');
      
      return InstallationResult(
        success: true,
        output: output.toString(),
        installTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return InstallationResult(
        success: false,
        output: output.toString(),
        error: 'AppImage installation failed: $e',
        installTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// Perform security scan on the file using selected provider
  Future<InstallationResult?> _performVirusScan(String filePath) async {
    try {
      // Check if security scanner is configured
      if (!await _securityScanner.isConfigured()) {
        final provider = await ApiConfig.getSelectedProvider();
        return InstallationResult(
          success: false,
          output: '',
          error: '${provider.name} API key not configured. Please configure it in Settings.',
          installTime: Duration.zero,
        );
      }

      // Check file size eligibility
      if (!await _securityScanner.isFileEligibleForScanning(filePath)) {
        final fileSize = await _securityScanner.getFileSize(filePath);
        final maxSize = await ApiConfig.getMaxFileSize();
        final provider = await ApiConfig.getSelectedProvider();
        return InstallationResult(
          success: false,
          output: '',
          error: 'File too large for scanning ($fileSize). Maximum size: ${_formatFileSize(maxSize)} for ${provider.name}.',
          installTime: Duration.zero,
        );
      }

      // Scan the file with the selected provider
      final report = await _securityScanner.scanFile(filePath);

      // Store scan report
      final storedReport = report.toStoredScanReport().copyWith(provider: report.provider);
      await _scanReportManager.saveScanReport(storedReport);

      // Check if file is safe to install
      if (report.isMalicious) {
        return InstallationResult(
          success: false,
          output: '${report.provider.name} Scan Results:\n'
              'Risk Level: ${report.riskLevel}\n'
              'Detections: ${report.positives}/${report.total}\n'
              'Detected Threats:\n${report.detectedThreats.join('\n')}',
          error: 'File flagged as malicious by ${report.provider.name}. Installation blocked for safety.',
          installTime: Duration.zero,
        );
      } else if (report.isSuspicious) {
        return InstallationResult(
          success: false,
          output: '${report.provider.name} Scan Results:\n'
              'Risk Level: ${report.riskLevel}\n'
              'Detections: ${report.positives}/${report.total}\n'
              'Detected Threats:\n${report.detectedThreats.join('\n')}',
          error: 'File flagged as suspicious by ${report.provider.name}. Please review before installation.',
          installTime: Duration.zero,
        );
      }

      // File is clean, proceed with installation
      return null;
    } catch (e) {
      return InstallationResult(
        success: false,
        output: '',
        error: 'VirusTotal scan failed: $e',
        installTime: Duration.zero,
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}