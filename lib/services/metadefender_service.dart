import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';
import '../models/security_provider.dart';

class MetaDefenderService {
  final Dio _dio = Dio();

  MetaDefenderService() {
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers = {
      'User-Agent': 'PackageArmor/1.0.0',
    };
  }

  /// Check if MetaDefender API is properly configured
  Future<bool> isConfigured() async {
    return await ApiConfig.isProviderConfigured(SecurityProvider.metaDefender);
  }

  /// Check if file is eligible for scanning (size limit)
  Future<bool> isFileEligibleForScanning(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      final maxSize = await ApiConfig.getMaxFileSizeForProvider(
          SecurityProvider.metaDefender);
      return fileSize <= maxSize;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in human readable format
  Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      return _formatFileSize(fileSize);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Calculate SHA256 hash of the file
  Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if file report already exists by hash
  Future<MetaDefenderReport?> getExistingReport(String fileHash) async {
    if (!await isConfigured()) {
      throw MetaDefenderException('MetaDefender API key not configured');
    }

    final apiKey = await ApiConfig.getApiKey(SecurityProvider.metaDefender);

    try {
      final response = await _dio.get(
        '${SecurityProvider.metaDefender.baseUrl}/hash/$fileHash',
        options: Options(
          headers: {
            'apikey': apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return MetaDefenderReport.fromJson(data);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null; // File not found in database
      }
      throw MetaDefenderException('Failed to get existing report: $e');
    }
  }

  /// Upload file for scanning
  Future<String> uploadFileForScanning(String filePath) async {
    if (!await isConfigured()) {
      throw MetaDefenderException('MetaDefender API key not configured');
    }

    final apiKey = await ApiConfig.getApiKey(SecurityProvider.metaDefender);

    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      final fileBytes = await file.readAsBytes();

      final response = await _dio.post(
        '${SecurityProvider.metaDefender.baseUrl}/file',
        data: fileBytes,
        options: Options(
          headers: {
            'apikey': apiKey,
            'filename': fileName,
            'Content-Type': 'application/octet-stream',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['data_id'];
      } else {
        throw MetaDefenderException(
            'Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is MetaDefenderException) rethrow;
      throw MetaDefenderException('Failed to upload file: $e');
    }
  }

  /// Get scan report by data ID
  Future<MetaDefenderReport?> getScanReport(String dataId) async {
    if (!await isConfigured()) {
      throw MetaDefenderException('MetaDefender API key not configured');
    }

    final apiKey = await ApiConfig.getApiKey(SecurityProvider.metaDefender);

    try {
      final response = await _dio.get(
        '${SecurityProvider.metaDefender.baseUrl}/file/$dataId',
        options: Options(
          headers: {
            'apikey': apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final scanProgress = data['scan_results']?['progress_percentage'] ?? 0;

        if (scanProgress == 100) {
          return MetaDefenderReport.fromJson(data);
        } else {
          // Still scanning
          return null;
        }
      } else {
        throw MetaDefenderException(
            'Failed to get report with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is MetaDefenderException) rethrow;
      throw MetaDefenderException('Failed to get scan report: $e');
    }
  }

  /// Poll for scan results with timeout
  Future<MetaDefenderReport> waitForScanResults(
    String dataId, {
    Duration? timeout,
    Duration? pollInterval,
  }) async {
    timeout ??= ApiConfig.scanTimeout;
    pollInterval ??= ApiConfig.pollInterval;
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      final report = await getScanReport(dataId);
      if (report != null) {
        return report;
      }

      await Future.delayed(pollInterval);
    }

    throw MetaDefenderException(
        'Scan timeout: Results not available within ${timeout.inMinutes} minutes');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class MetaDefenderReport {
  final String dataId;
  final String sha256;
  final String md5;
  final String sha1;
  final DateTime scanDate;
  final int positives;
  final int total;
  final String permalink;
  final Map<String, ScanEngineResult> scanResults;

  MetaDefenderReport({
    required this.dataId,
    required this.sha256,
    required this.md5,
    required this.sha1,
    required this.scanDate,
    required this.positives,
    required this.total,
    required this.permalink,
    required this.scanResults,
  });

  factory MetaDefenderReport.fromJson(Map<String, dynamic> json) {
    final scanResultsData =
        json['scan_results']?['scan_details'] as Map<String, dynamic>? ?? {};
    final scanResults = <String, ScanEngineResult>{};

    int positiveCount = 0;
    int totalCount = 0;

    for (final entry in scanResultsData.entries) {
      final result = ScanEngineResult.fromJson(entry.value);
      scanResults[entry.key] = result;
      totalCount++;
      if (result.detected) {
        positiveCount++;
      }
    }

    return MetaDefenderReport(
      dataId: json['data_id'] ?? '',
      sha256: json['file_info']?['sha256'] ?? '',
      md5: json['file_info']?['md5'] ?? '',
      sha1: json['file_info']?['sha1'] ?? '',
      scanDate: DateTime.parse(json['scan_results']?['start_time'] ??
          DateTime.now().toIso8601String()),
      positives: positiveCount,
      total: totalCount,
      permalink:
          'https://metadefender.opswat.com/results/file/${json['data_id']}/regular/overview',
      scanResults: scanResults,
    );
  }

  bool get isClean => positives == 0;
  bool get isSuspicious => positives > 0 && positives <= 3;
  bool get isMalicious => positives > 3;

  double get detectionRate => total > 0 ? (positives / total) * 100 : 0.0;

  String get riskLevel {
    if (isClean) return 'Clean';
    if (isSuspicious) return 'Suspicious';
    return 'Malicious';
  }

  List<String> get detectedThreats {
    return scanResults.entries
        .where((entry) => entry.value.detected)
        .map((entry) => '${entry.key}: ${entry.value.threatName}')
        .toList();
  }
}

class ScanEngineResult {
  final bool detected;
  final String threatName;
  final int scanResult;
  final String defName;

  ScanEngineResult({
    required this.detected,
    required this.threatName,
    required this.scanResult,
    required this.defName,
  });

  factory ScanEngineResult.fromJson(Map<String, dynamic> json) {
    final scanResult = json['scan_result_i'] ?? 0;
    return ScanEngineResult(
      detected: scanResult == 1, // 1 = infected, 0 = clean
      threatName: json['threat_found'] ?? '',
      scanResult: scanResult,
      defName: json['def_name'] ?? '',
    );
  }
}

class MetaDefenderException implements Exception {
  final String message;

  MetaDefenderException(this.message);

  @override
  String toString() => 'MetaDefenderException: $message';
}
