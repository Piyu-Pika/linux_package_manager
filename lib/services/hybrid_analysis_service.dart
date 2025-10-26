import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';
import '../models/security_provider.dart';

class HybridAnalysisService {
  final Dio _dio = Dio();

  HybridAnalysisService() {
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers = {
      'User-Agent': 'PackageArmor/1.0.0',
    };
  }

  /// Check if Hybrid Analysis API is properly configured
  Future<bool> isConfigured() async {
    return await ApiConfig.isProviderConfigured(
        SecurityProvider.hybridAnalysis);
  }

  /// Check if file is eligible for scanning (size limit)
  Future<bool> isFileEligibleForScanning(String filePath) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      final maxSize = await ApiConfig.getMaxFileSizeForProvider(
          SecurityProvider.hybridAnalysis);
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
  Future<HybridAnalysisReport?> getExistingReport(String fileHash) async {
    if (!await isConfigured()) {
      throw HybridAnalysisException('Hybrid Analysis API key not configured');
    }

    final apiKey = await ApiConfig.getApiKey(SecurityProvider.hybridAnalysis);

    try {
      final response = await _dio.get(
        '${SecurityProvider.hybridAnalysis.baseUrl}/search/hash',
        queryParameters: {
          'hash': fileHash,
        },
        options: Options(
          headers: {
            'api-key': apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return HybridAnalysisReport.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      throw HybridAnalysisException('Failed to get existing report: $e');
    }
  }

  /// Upload file for scanning
  Future<String> uploadFileForScanning(String filePath) async {
    if (!await isConfigured()) {
      throw HybridAnalysisException('Hybrid Analysis API key not configured');
    }

    final apiKey = await ApiConfig.getApiKey(SecurityProvider.hybridAnalysis);

    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'environment_id': 300, // Linux Ubuntu 20.04 64-bit
        'no_share_third_party': false,
        'allow_community_access': true,
      });

      final response = await _dio.post(
        '${SecurityProvider.hybridAnalysis.baseUrl}/submit/file',
        data: formData,
        options: Options(
          headers: {
            'api-key': apiKey,
          },
        ),
      );

      if (response.statusCode == 201) {
        final data = response.data;
        return data['job_id'].toString();
      } else {
        throw HybridAnalysisException(
            'Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HybridAnalysisException) rethrow;
      throw HybridAnalysisException('Failed to upload file: $e');
    }
  }

  /// Get scan report by job ID
  Future<HybridAnalysisReport?> getScanReport(String jobId) async {
    if (!await isConfigured()) {
      throw HybridAnalysisException('Hybrid Analysis API key not configured');
    }

    final apiKey = await ApiConfig.getApiKey(SecurityProvider.hybridAnalysis);

    try {
      final response = await _dio.get(
        '${SecurityProvider.hybridAnalysis.baseUrl}/report/$jobId/summary',
        options: Options(
          headers: {
            'api-key': apiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['state'] == 'SUCCESS') {
          return HybridAnalysisReport.fromJson(data);
        } else if (data['state'] == 'IN_PROGRESS' ||
            data['state'] == 'IN_QUEUE') {
          // Still processing
          return null;
        } else {
          throw HybridAnalysisException('Analysis failed: ${data['state']}');
        }
      } else {
        throw HybridAnalysisException(
            'Failed to get report with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is HybridAnalysisException) rethrow;
      throw HybridAnalysisException('Failed to get scan report: $e');
    }
  }

  /// Poll for scan results with timeout
  Future<HybridAnalysisReport> waitForScanResults(
    String jobId, {
    Duration? timeout,
    Duration? pollInterval,
  }) async {
    timeout ??= ApiConfig.scanTimeout;
    pollInterval ??= ApiConfig.pollInterval;
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      final report = await getScanReport(jobId);
      if (report != null) {
        return report;
      }

      await Future.delayed(pollInterval);
    }

    throw HybridAnalysisException(
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

class HybridAnalysisReport {
  final String jobId;
  final String sha256;
  final String md5;
  final String sha1;
  final DateTime submitTime;
  final int threatScore; // 0-100
  final String verdict;
  final String permalink;
  final List<String> detectedMalware;
  final Map<String, dynamic> behaviorAnalysis;

  HybridAnalysisReport({
    required this.jobId,
    required this.sha256,
    required this.md5,
    required this.sha1,
    required this.submitTime,
    required this.threatScore,
    required this.verdict,
    required this.permalink,
    required this.detectedMalware,
    required this.behaviorAnalysis,
  });

  factory HybridAnalysisReport.fromJson(Map<String, dynamic> json) {
    final malwareList = <String>[];
    if (json['extracted_files'] != null) {
      for (final file in json['extracted_files']) {
        if (file['threat_level_readable'] != null &&
            file['threat_level_readable'] != 'no specific threat') {
          malwareList.add('${file['name']}: ${file['threat_level_readable']}');
        }
      }
    }

    return HybridAnalysisReport(
      jobId: json['job_id']?.toString() ?? '',
      sha256: json['sha256'] ?? '',
      md5: json['md5'] ?? '',
      sha1: json['sha1'] ?? '',
      submitTime: DateTime.parse(
          json['submit_name'] ?? DateTime.now().toIso8601String()),
      threatScore: json['threat_score'] ?? 0,
      verdict: json['verdict'] ?? 'unknown',
      permalink: json['webif_url'] ?? '',
      detectedMalware: malwareList,
      behaviorAnalysis: json['behavior'] ?? {},
    );
  }

  bool get isClean =>
      threatScore == 0 && verdict.toLowerCase() == 'no specific threat';
  bool get isSuspicious => threatScore > 0 && threatScore <= 50;
  bool get isMalicious => threatScore > 50;

  double get detectionRate => threatScore.toDouble();

  String get riskLevel {
    if (isClean) return 'Clean';
    if (isSuspicious) return 'Suspicious';
    return 'Malicious';
  }

  List<String> get detectedThreats {
    final threats = <String>[];
    if (verdict != 'no specific threat') {
      threats.add('Verdict: $verdict');
    }
    threats.addAll(detectedMalware);
    return threats;
  }

  // Convert to common format for compatibility
  int get positives => threatScore > 0 ? 1 : 0;
  int get total => 1; // Hybrid Analysis provides a single verdict
  DateTime get scanDate => submitTime;
}

class HybridAnalysisException implements Exception {
  final String message;

  HybridAnalysisException(this.message);

  @override
  String toString() => 'HybridAnalysisException: $message';
}
