import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';

class VirusTotalService {
  final Dio _dio = Dio();

  VirusTotalService() {
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
  }

  /// Check if VirusTotal API is properly configured
  Future<bool> isConfigured() async => await ApiConfig.isApiKeyConfigured();

  /// Check if file is eligible for scanning (size limit)
  Future<bool> isFileEligibleForScanning(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      return fileSize <= ApiConfig.maxFileSizeForScanning;
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
  Future<VirusTotalReport?> getExistingReport(String fileHash) async {
    if (!await isConfigured()) {
      throw VirusTotalException('VirusTotal API key not configured');
    }
    
    final apiKey = await ApiConfig.getVirusTotalApiKey();
    
    try {
      final response = await _dio.get(
        '${ApiConfig.virusTotalBaseUrl}/file/report',
        queryParameters: {
          'apikey': apiKey,
          'resource': fileHash,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['response_code'] == 1) {
          return VirusTotalReport.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      throw VirusTotalException('Failed to get existing report: $e');
    }
  }

  /// Upload file for scanning
  Future<String> uploadFileForScanning(String filePath) async {
    if (!await isConfigured()) {
      throw VirusTotalException('VirusTotal API key not configured');
    }
    
    final apiKey = await ApiConfig.getVirusTotalApiKey();
    
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      final formData = FormData.fromMap({
        'apikey': apiKey,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        '${ApiConfig.virusTotalBaseUrl}/file/scan',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['response_code'] == 1) {
          return data['scan_id'];
        } else {
          throw VirusTotalException(data['verbose_msg'] ?? 'Upload failed');
        }
      } else {
        throw VirusTotalException('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is VirusTotalException) rethrow;
      throw VirusTotalException('Failed to upload file: $e');
    }
  }

  /// Get scan report by scan ID
  Future<VirusTotalReport?> getScanReport(String scanId) async {
    if (!await isConfigured()) {
      throw VirusTotalException('VirusTotal API key not configured');
    }
    
    final apiKey = await ApiConfig.getVirusTotalApiKey();
    
    try {
      final response = await _dio.get(
        '${ApiConfig.virusTotalBaseUrl}/file/report',
        queryParameters: {
          'apikey': apiKey,
          'resource': scanId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['response_code'] == 1) {
          return VirusTotalReport.fromJson(data);
        } else if (data['response_code'] == -2) {
          // Still queued for analysis
          return null;
        } else {
          throw VirusTotalException(data['verbose_msg'] ?? 'Report not found');
        }
      } else {
        throw VirusTotalException('Failed to get report with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is VirusTotalException) rethrow;
      throw VirusTotalException('Failed to get scan report: $e');
    }
  }

  /// Poll for scan results with timeout
  Future<VirusTotalReport> waitForScanResults(String scanId, {
    Duration? timeout,
    Duration? pollInterval,
  }) async {
    timeout ??= ApiConfig.scanTimeout;
    pollInterval ??= ApiConfig.pollInterval;
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      final report = await getScanReport(scanId);
      if (report != null) {
        return report;
      }
      
      await Future.delayed(pollInterval);
    }
    
    throw VirusTotalException('Scan timeout: Results not available within ${timeout.inMinutes} minutes');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class VirusTotalReport {
  final String scanId;
  final String sha256;
  final String md5;
  final String sha1;
  final DateTime scanDate;
  final int positives;
  final int total;
  final String permalink;
  final Map<String, ScanResult> scans;

  VirusTotalReport({
    required this.scanId,
    required this.sha256,
    required this.md5,
    required this.sha1,
    required this.scanDate,
    required this.positives,
    required this.total,
    required this.permalink,
    required this.scans,
  });

  factory VirusTotalReport.fromJson(Map<String, dynamic> json) {
    final scansData = json['scans'] as Map<String, dynamic>? ?? {};
    final scans = <String, ScanResult>{};
    
    for (final entry in scansData.entries) {
      scans[entry.key] = ScanResult.fromJson(entry.value);
    }

    return VirusTotalReport(
      scanId: json['scan_id'] ?? '',
      sha256: json['sha256'] ?? '',
      md5: json['md5'] ?? '',
      sha1: json['sha1'] ?? '',
      scanDate: DateTime.parse(json['scan_date'] ?? DateTime.now().toIso8601String()),
      positives: json['positives'] ?? 0,
      total: json['total'] ?? 0,
      permalink: json['permalink'] ?? '',
      scans: scans,
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
    return scans.entries
        .where((entry) => entry.value.detected)
        .map((entry) => '${entry.key}: ${entry.value.result}')
        .toList();
  }
}

class ScanResult {
  final bool detected;
  final String? version;
  final String? result;
  final DateTime? update;

  ScanResult({
    required this.detected,
    this.version,
    this.result,
    this.update,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      detected: json['detected'] ?? false,
      version: json['version'],
      result: json['result'],
      update: json['update'] != null ? DateTime.parse(json['update']) : null,
    );
  }
}

class VirusTotalException implements Exception {
  final String message;
  
  VirusTotalException(this.message);
  
  @override
  String toString() => 'VirusTotalException: $message';
}