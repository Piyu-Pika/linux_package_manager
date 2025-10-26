import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/package_installer.dart';
import '../services/virustotal_service.dart';
import '../services/scan_report_manager.dart';
import '../models/scan_report.dart';

class InstallScreen extends StatefulWidget {
  const InstallScreen({super.key});

  @override
  State<InstallScreen> createState() => _InstallScreenState();
}

class _InstallScreenState extends State<InstallScreen> {
  final PackageInstaller _installer = PackageInstaller();
  final VirusTotalService _virusTotalService = VirusTotalService();
  final ScanReportManager _scanReportManager = ScanReportManager();

  bool _isInstalling = false;
  bool _isScanning = false;
  bool _isVirusTotalConfigured = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  String _installationLog = '';
  StoredScanReport? _currentScanReport;

  @override
  void initState() {
    super.initState();
    _checkVirusTotalConfiguration();
  }

  Future<void> _checkVirusTotalConfiguration() async {
    final isConfigured = await _virusTotalService.isConfigured();
    if (mounted) {
      setState(() {
        _isVirusTotalConfigured = isConfigured;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'deb',
          'rpm',
          'pkg',
          'tar.gz',
          'gz',
          'tar',
          'xz',
          'appimage',
          'AppImage'
        ],
        dialogTitle: 'Select Package File',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _installationLog = '';
          _currentScanReport = null;
        });

        // Check if we have an existing scan report
        await _checkExistingScanReport();

        // Refresh VirusTotal configuration status
        await _checkVirusTotalConfiguration();
      }
    } catch (e) {
      _showErrorDialog('Error picking file: $e');
    }
  }

  Future<void> _checkExistingScanReport() async {
    if (_selectedFilePath == null) return;

    try {
      final fileHash =
          await _virusTotalService.calculateFileHash(_selectedFilePath!);
      final existingReport =
          await _scanReportManager.getScanReportByHash(fileHash);

      if (existingReport != null) {
        setState(() {
          _currentScanReport = existingReport;
        });
      }
    } catch (e) {
      // Ignore errors when checking existing reports
    }
  }

  Future<void> _scanWithVirusTotal() async {
    if (_selectedFilePath == null) return;

    // Check if API is configured
    if (!await _virusTotalService.isConfigured()) {
      _showApiNotConfiguredDialog();
      return;
    }

    // Check if file is eligible for scanning
    final isEligible =
        await _virusTotalService.isFileEligibleForScanning(_selectedFilePath!);
    final fileSize = await _virusTotalService.getFileSize(_selectedFilePath!);

    if (!isEligible) {
      _showErrorDialog(
          'File is too large for VirusTotal scanning (max 32MB).\nFile size: $fileSize');
      return;
    }

    // Show scanning dialog
    if (!mounted) return;
    _showScanningDialog();
  }

  Future<void> _performVirusScan() async {
    try {
      setState(() {
        _isScanning = true;
      });

      // Calculate file hash
      final fileHash =
          await _virusTotalService.calculateFileHash(_selectedFilePath!);

      // Check for existing report first
      var report = await _virusTotalService.getExistingReport(fileHash);

      if (report == null) {
        // Upload file for scanning
        final scanId =
            await _virusTotalService.uploadFileForScanning(_selectedFilePath!);

        // Wait for results
        report = await _virusTotalService.waitForScanResults(scanId);
      }

      // Store the report
      final storedReport = StoredScanReport.fromVirusTotalReport(
        _selectedFilePath!,
        _selectedFileName!,
        fileHash,
        report,
      );

      await _scanReportManager.saveScanReport(storedReport);

      setState(() {
        _currentScanReport = storedReport;
        _isScanning = false;
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close scanning dialog
        _showScanResultDialog(storedReport);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close scanning dialog
        _showErrorDialog('Virus scan failed: $e');
      }
    }
  }

  Future<void> _installPackage({bool bypassScan = false}) async {
    if (_selectedFilePath == null) {
      _showErrorDialog('Please select a package file first');
      return;
    }

    // Check if we need to show risk warning
    if (!bypassScan &&
        _currentScanReport != null &&
        !_currentScanReport!.isClean) {
      _showRiskWarningDialog();
      return;
    }

    setState(() {
      _isInstalling = true;
      _installationLog = 'Starting installation...\n';
    });

    try {
      final result = await _installer.installPackage(_selectedFilePath!);

      setState(() {
        _isInstalling = false;
        _installationLog += result.output;
      });

      if (result.success) {
        _showSuccessDialog('Package installed successfully!');
        setState(() {
          _selectedFilePath = null;
          _selectedFileName = null;
          _currentScanReport = null;
        });
      } else {
        _showErrorDialog('Installation failed:\n${result.error}');
      }
    } catch (e) {
      setState(() {
        _isInstalling = false;
        _installationLog += 'Error: $e\n';
      });
      _showErrorDialog('Installation failed: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showScanningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Scanning with VirusTotal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scanning $_selectedFileName for viruses...'),
            const SizedBox(height: 16),
            const Text(
              'This may take a few minutes. Please wait while we analyze the file.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isScanning = false;
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // Start the actual scanning
    _performVirusScan();
  }

  void _showScanResultDialog(StoredScanReport report) {
    final isClean = report.isClean;
    final isSuspicious = report.isSuspicious;
    final isMalicious = report.isMalicious;

    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;

    if (isSuspicious) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (isMalicious) {
      statusColor = Colors.red;
      statusIcon = Icons.dangerous;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Scan Results',
                style: TextStyle(color: statusColor),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          report.riskLevel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '${report.positives}/${report.total} engines detected threats'),
                    if (report.detectionRate > 0)
                      Text(
                          'Detection rate: ${report.detectionRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              if (report.detectedThreats.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Detected Threats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: report.detectedThreats.take(5).map((threat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $threat',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (report.detectedThreats.length > 5)
                  Text(
                    '... and ${report.detectedThreats.length - 5} more',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
              const SizedBox(height: 16),
              Text(
                'Scanned on: ${report.scanDate.toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('View Details'),
          ),
          if (isClean)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _installPackage(bypassScan: true);
              },
              child: const Text('Install'),
            )
          else
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _installPackage(bypassScan: true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Install Anyway'),
            ),
        ],
      ),
    );
  }

  void _showRiskWarningDialog() {
    bool canProceed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Auto-enable button after 5 seconds
          if (!canProceed) {
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setDialogState(() {
                  canProceed = true;
                });
              }
            });
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 12),
                Text('Security Risk Warning'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dangerous, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'POTENTIAL THREAT DETECTED',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('File: ${_currentScanReport?.fileName}'),
                      Text('Risk Level: ${_currentScanReport?.riskLevel}'),
                      Text(
                          'Detections: ${_currentScanReport?.positives}/${_currentScanReport?.total}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This file has been flagged by virus scanners. Installing it may harm your system.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only proceed if you trust the source and understand the risks.',
                  style: TextStyle(color: Colors.grey),
                ),
                if (!canProceed) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Please wait ${5} seconds before proceeding...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: canProceed
                    ? () {
                        Navigator.pop(context);
                        _installPackage(bypassScan: true);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: canProceed ? Colors.red : Colors.grey,
                ),
                child: const Text('Install Anyway'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showApiNotConfiguredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.orange),
            SizedBox(width: 12),
            Text('VirusTotal API Not Configured'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To use virus scanning, you need to configure your VirusTotal API key.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text('Quick setup:'),
            SizedBox(height: 8),
            Text('1. Go to Settings → Security & Virus Scanning'),
            Text('2. Click "Configure API Key"'),
            Text('3. Follow the instructions to get your free key'),
            SizedBox(height: 16),
            Text('Or manually:'),
            SizedBox(height: 8),
            Text('1. Visit virustotal.com'),
            Text('2. Create a free account'),
            Text('3. Go to your profile → API Key'),
            Text('4. Copy the 64-character key'),
            SizedBox(height: 16),
            Text(
              'Note: Free accounts have a 32MB file size limit and 4 requests per minute.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to settings - you might need to implement this navigation
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Go to Settings → Security & Virus Scanning to configure'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16)),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Install Local Package',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Install packages from local files on your system',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // File picker section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.file_download_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Package File',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Choose a package file from your computer',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Supported formats
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Supported Formats',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildFormatChip(
                                      '.deb', 'Debian Package', Colors.red),
                                  _buildFormatChip(
                                      '.rpm', 'Red Hat Package', Colors.blue),
                                  _buildFormatChip(
                                      '.pkg', 'Package File', Colors.green),
                                  _buildFormatChip('.tar.gz',
                                      'Compressed Archive', Colors.orange),
                                  _buildFormatChip('.AppImage', 'Portable App',
                                      Colors.purple),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // File selection area
                        GestureDetector(
                          onTap: _isInstalling ? null : _pickFile,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedFileName != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.3),
                                width: 2,
                                style: _selectedFileName != null
                                    ? BorderStyle.solid
                                    : BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: _selectedFileName != null
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.1)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.3),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _selectedFileName != null
                                      ? Icons.check_circle_rounded
                                      : Icons.cloud_upload_rounded,
                                  size: 48,
                                  color: _selectedFileName != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFileName ??
                                      'Click to select a package file',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _selectedFileName != null
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_selectedFileName == null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'or drag and drop a file here',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Scan results display
                        if (_currentScanReport != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getScanResultColor(_currentScanReport!)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getScanResultColor(_currentScanReport!)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getScanResultIcon(_currentScanReport!),
                                      color: _getScanResultColor(
                                          _currentScanReport!),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Scan Results: ${_currentScanReport!.riskLevel}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _getScanResultColor(
                                            _currentScanReport!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_currentScanReport!.positives}/${_currentScanReport!.total} engines detected threats',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (_currentScanReport!.detectionRate > 0)
                                  Text(
                                    'Detection rate: ${_currentScanReport!.detectionRate.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Action buttons
                        Column(
                          children: [
                            // First row: Clear and Scan buttons
                            if (_selectedFileName != null)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isInstalling || _isScanning
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedFilePath = null;
                                                _selectedFileName = null;
                                                _installationLog = '';
                                                _currentScanReport = null;
                                              });
                                            },
                                      icon: const Icon(Icons.clear_rounded),
                                      label: const Text('Clear'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isInstalling ||
                                              _isScanning ||
                                              _selectedFilePath == null
                                          ? null
                                          : _scanWithVirusTotal,
                                      icon: _isScanning
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : Icon(
                                              _isVirusTotalConfigured
                                                  ? Icons.security_rounded
                                                  : Icons.key_rounded,
                                            ),
                                      label: Text(
                                        _isScanning
                                            ? 'Scanning...'
                                            : _isVirusTotalConfigured
                                                ? 'Scan for Viruses'
                                                : 'Setup Virus Scan',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: _currentScanReport?.isClean ==
                                                  true
                                              ? Colors.green
                                              : _currentScanReport != null
                                                  ? Colors.orange
                                                  : _isVirusTotalConfigured
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .outline
                                                      : Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            if (_selectedFileName != null)
                              const SizedBox(height: 16),

                            // Second row: Install button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isInstalling ||
                                        _isScanning ||
                                        _selectedFilePath == null
                                    ? null
                                    : () => _installPackage(),
                                icon: _isInstalling
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.install_desktop_rounded),
                                label: Text(
                                  _isInstalling
                                      ? 'Installing...'
                                      : 'Install Package',
                                ),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: _currentScanReport != null &&
                                          !_currentScanReport!.isClean
                                      ? Colors.orange
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Installation log
                if (_installationLog.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.terminal_rounded,
                                  size: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Installation Log',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 300,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _installationLog,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatChip(String format, String description, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            format,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScanResultColor(StoredScanReport report) {
    if (report.isClean) return Colors.green;
    if (report.isSuspicious) return Colors.orange;
    return Colors.red;
  }

  IconData _getScanResultIcon(StoredScanReport report) {
    if (report.isClean) return Icons.check_circle_rounded;
    if (report.isSuspicious) return Icons.warning_rounded;
    return Icons.dangerous_rounded;
  }
}
