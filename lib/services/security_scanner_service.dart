import '../config/api_config.dart';
import '../models/security_provider.dart';
import '../models/scan_report.dart';
import 'virustotal_service.dart';
import 'hybrid_analysis_service.dart';
import 'metadefender_service.dart';

class SecurityScannerService {
  final VirusTotalService _virusTotalService = VirusTotalService();
  final HybridAnalysisService _hybridAnalysisService = HybridAnalysisService();
  final MetaDefenderService _metaDefenderService = MetaDefenderService();

  /// Check if current security provider is properly configured
  Future<bool> isConfigured() async {
    final provider = await ApiConfig.getSelectedProvider();
    switch (provider) {
      case SecurityProvider.virusTotal:
        return await _virusTotalService.isConfigured();
      case SecurityProvider.hybridAnalysis:
        return await _hybridAnalysisService.isConfigured();
      case SecurityProvider.metaDefender:
        return await _metaDefenderService.isConfigured();
    }
  }

  /// Check if file is eligible for scanning with current provider
  Future<bool> isFileEligibleForScanning(String filePath) async {
    final provider = await ApiConfig.getSelectedProvider();
    switch (provider) {
      case SecurityProvider.virusTotal:
        return await _virusTotalService.isFileEligibleForScanning(filePath);
      case SecurityProvider.hybridAnalysis:
        return await _hybridAnalysisService.isFileEligibleForScanning(filePath);
      case SecurityProvider.metaDefender:
        return await _metaDefenderService.isFileEligibleForScanning(filePath);
    }
  }

  /// Get file size in human readable format
  Future<String> getFileSize(String filePath) async {
    final provider = await ApiConfig.getSelectedProvider();
    switch (provider) {
      case SecurityProvider.virusTotal:
        return await _virusTotalService.getFileSize(filePath);
      case SecurityProvider.hybridAnalysis:
        return await _hybridAnalysisService.getFileSize(filePath);
      case SecurityProvider.metaDefender:
        return await _metaDefenderService.getFileSize(filePath);
    }
  }

  /// Calculate file hash
  Future<String> calculateFileHash(String filePath) async {
    final provider = await ApiConfig.getSelectedProvider();
    switch (provider) {
      case SecurityProvider.virusTotal:
        return await _virusTotalService.calculateFileHash(filePath);
      case SecurityProvider.hybridAnalysis:
        return await _hybridAnalysisService.calculateFileHash(filePath);
      case SecurityProvider.metaDefender:
        return await _metaDefenderService.calculateFileHash(filePath);
    }
  }

  /// Scan file with current provider and return unified report
  Future<UnifiedScanReport> scanFile(String filePath) async {
    final provider = await ApiConfig.getSelectedProvider();
    final fileHash = await calculateFileHash(filePath);
    final fileName = filePath.split('/').last;

    // Check for existing report first
    final existingReport = await _getExistingReport(provider, fileHash);
    if (existingReport != null) {
      return existingReport;
    }

    // Upload and scan file
    final scanId = await _uploadFile(provider, filePath);
    final report = await _waitForResults(provider, scanId);
    
    return UnifiedScanReport(
      provider: provider,
      filePath: filePath,
      fileName: fileName,
      fileHash: fileHash,
      scanDate: report.scanDate,
      positives: report.positives,
      total: report.total,
      riskLevel: report.riskLevel,
      detectedThreats: report.detectedThreats,
      permalink: report.permalink,
      rawReport: report,
    );
  }

  Future<UnifiedScanReport?> _getExistingReport(SecurityProvider provider, String fileHash) async {
    try {
      switch (provider) {
        case SecurityProvider.virusTotal:
          final report = await _virusTotalService.getExistingReport(fileHash);
          return report != null ? _convertVirusTotalReport(report, '', '', fileHash) : null;
        case SecurityProvider.hybridAnalysis:
          final report = await _hybridAnalysisService.getExistingReport(fileHash);
          return report != null ? _convertHybridAnalysisReport(report, '', '', fileHash) : null;
        case SecurityProvider.metaDefender:
          final report = await _metaDefenderService.getExistingReport(fileHash);
          return report != null ? _convertMetaDefenderReport(report, '', '', fileHash) : null;
      }
    } catch (e) {
      return null; // No existing report found
    }
  }

  Future<String> _uploadFile(SecurityProvider provider, String filePath) async {
    switch (provider) {
      case SecurityProvider.virusTotal:
        return await _virusTotalService.uploadFileForScanning(filePath);
      case SecurityProvider.hybridAnalysis:
        return await _hybridAnalysisService.uploadFileForScanning(filePath);
      case SecurityProvider.metaDefender:
        return await _metaDefenderService.uploadFileForScanning(filePath);
    }
  }

  Future<UnifiedScanReport> _waitForResults(SecurityProvider provider, String scanId) async {
    switch (provider) {
      case SecurityProvider.virusTotal:
        final report = await _virusTotalService.waitForScanResults(scanId);
        return _convertVirusTotalReport(report, '', '', report.sha256);
      case SecurityProvider.hybridAnalysis:
        final report = await _hybridAnalysisService.waitForScanResults(scanId);
        return _convertHybridAnalysisReport(report, '', '', report.sha256);
      case SecurityProvider.metaDefender:
        final report = await _metaDefenderService.waitForScanResults(scanId);
        return _convertMetaDefenderReport(report, '', '', report.sha256);
    }
  }

  UnifiedScanReport _convertVirusTotalReport(VirusTotalReport report, String filePath, String fileName, String fileHash) {
    return UnifiedScanReport(
      provider: SecurityProvider.virusTotal,
      filePath: filePath,
      fileName: fileName,
      fileHash: fileHash,
      scanDate: report.scanDate,
      positives: report.positives,
      total: report.total,
      riskLevel: report.riskLevel,
      detectedThreats: report.detectedThreats,
      permalink: report.permalink,
      rawReport: report,
    );
  }

  UnifiedScanReport _convertHybridAnalysisReport(HybridAnalysisReport report, String filePath, String fileName, String fileHash) {
    return UnifiedScanReport(
      provider: SecurityProvider.hybridAnalysis,
      filePath: filePath,
      fileName: fileName,
      fileHash: fileHash,
      scanDate: report.scanDate,
      positives: report.positives,
      total: report.total,
      riskLevel: report.riskLevel,
      detectedThreats: report.detectedThreats,
      permalink: report.permalink,
      rawReport: report,
    );
  }

  UnifiedScanReport _convertMetaDefenderReport(MetaDefenderReport report, String filePath, String fileName, String fileHash) {
    return UnifiedScanReport(
      provider: SecurityProvider.metaDefender,
      filePath: filePath,
      fileName: fileName,
      fileHash: fileHash,
      scanDate: report.scanDate,
      positives: report.positives,
      total: report.total,
      riskLevel: report.riskLevel,
      detectedThreats: report.detectedThreats,
      permalink: report.permalink,
      rawReport: report,
    );
  }
}

class UnifiedScanReport {
  final SecurityProvider provider;
  final String filePath;
  final String fileName;
  final String fileHash;
  final DateTime scanDate;
  final int positives;
  final int total;
  final String riskLevel;
  final List<String> detectedThreats;
  final String permalink;
  final dynamic rawReport;

  UnifiedScanReport({
    required this.provider,
    required this.filePath,
    required this.fileName,
    required this.fileHash,
    required this.scanDate,
    required this.positives,
    required this.total,
    required this.riskLevel,
    required this.detectedThreats,
    required this.permalink,
    required this.rawReport,
  });

  bool get isClean => positives == 0;
  bool get isSuspicious => positives > 0 && positives <= 3;
  bool get isMalicious => positives > 3;
  
  double get detectionRate => total > 0 ? (positives / total) * 100 : 0.0;

  /// Convert to StoredScanReport for persistence
  StoredScanReport toStoredScanReport() {
    return StoredScanReport(
      filePath: filePath,
      fileName: fileName,
      fileHash: fileHash,
      scanDate: scanDate,
      positives: positives,
      total: total,
      riskLevel: riskLevel,
      detectedThreats: detectedThreats,
      permalink: permalink,
    );
  }
}