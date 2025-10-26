import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_report.dart';

class ScanReportManager {
  static const String _reportsKey = 'virus_scan_reports';

  /// Save a scan report
  Future<void> saveScanReport(StoredScanReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getAllScanReports();

    // Remove existing report for the same file hash
    reports.removeWhere((r) => r.fileHash == report.fileHash);

    // Add new report
    reports.add(report);

    // Keep only last 50 reports to avoid storage bloat
    if (reports.length > 50) {
      reports.sort((a, b) => b.scanDate.compareTo(a.scanDate));
      reports.removeRange(50, reports.length);
    }

    final reportsJson = reports.map((r) => r.toJson()).toList();
    await prefs.setString(_reportsKey, jsonEncode(reportsJson));
  }

  /// Get all scan reports
  Future<List<StoredScanReport>> getAllScanReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsString = prefs.getString(_reportsKey);

    if (reportsString == null) return [];

    try {
      final reportsJson = jsonDecode(reportsString) as List;
      return reportsJson
          .map((json) => StoredScanReport.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get scan report by file hash
  Future<StoredScanReport?> getScanReportByHash(String fileHash) async {
    final reports = await getAllScanReports();
    try {
      return reports.firstWhere((r) => r.fileHash == fileHash);
    } catch (e) {
      return null;
    }
  }

  /// Update user risk acceptance
  Future<void> updateRiskAcceptance(String fileHash, bool accepted) async {
    final reports = await getAllScanReports();
    final reportIndex = reports.indexWhere((r) => r.fileHash == fileHash);

    if (reportIndex != -1) {
      reports[reportIndex] = reports[reportIndex].copyWith(
        userAcceptedRisk: accepted,
      );

      final prefs = await SharedPreferences.getInstance();
      final reportsJson = reports.map((r) => r.toJson()).toList();
      await prefs.setString(_reportsKey, jsonEncode(reportsJson));
    }
  }

  /// Clear all scan reports
  Future<void> clearAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportsKey);
  }

  /// Get reports by risk level
  Future<List<StoredScanReport>> getReportsByRiskLevel(String riskLevel) async {
    final reports = await getAllScanReports();
    return reports.where((r) => r.riskLevel == riskLevel).toList();
  }
}
