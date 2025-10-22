class StoredScanReport {
  final String filePath;
  final String fileName;
  final String fileHash;
  final DateTime scanDate;
  final int positives;
  final int total;
  final String riskLevel;
  final List<String> detectedThreats;
  final String permalink;
  final bool userAcceptedRisk;

  StoredScanReport({
    required this.filePath,
    required this.fileName,
    required this.fileHash,
    required this.scanDate,
    required this.positives,
    required this.total,
    required this.riskLevel,
    required this.detectedThreats,
    required this.permalink,
    this.userAcceptedRisk = false,
  });

  factory StoredScanReport.fromVirusTotalReport(
    String filePath,
    String fileName,
    String fileHash,
    dynamic virusTotalReport,
  ) {
    return StoredScanReport(
      filePath: filePath,
      fileName: fileName,
      fileHash: fileHash,
      scanDate: virusTotalReport.scanDate,
      positives: virusTotalReport.positives,
      total: virusTotalReport.total,
      riskLevel: virusTotalReport.riskLevel,
      detectedThreats: virusTotalReport.detectedThreats,
      permalink: virusTotalReport.permalink,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'fileHash': fileHash,
      'scanDate': scanDate.toIso8601String(),
      'positives': positives,
      'total': total,
      'riskLevel': riskLevel,
      'detectedThreats': detectedThreats,
      'permalink': permalink,
      'userAcceptedRisk': userAcceptedRisk,
    };
  }

  factory StoredScanReport.fromJson(Map<String, dynamic> json) {
    return StoredScanReport(
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      fileHash: json['fileHash'] ?? '',
      scanDate: DateTime.parse(json['scanDate'] ?? DateTime.now().toIso8601String()),
      positives: json['positives'] ?? 0,
      total: json['total'] ?? 0,
      riskLevel: json['riskLevel'] ?? 'Unknown',
      detectedThreats: List<String>.from(json['detectedThreats'] ?? []),
      permalink: json['permalink'] ?? '',
      userAcceptedRisk: json['userAcceptedRisk'] ?? false,
    );
  }

  StoredScanReport copyWith({
    String? filePath,
    String? fileName,
    String? fileHash,
    DateTime? scanDate,
    int? positives,
    int? total,
    String? riskLevel,
    List<String>? detectedThreats,
    String? permalink,
    bool? userAcceptedRisk,
  }) {
    return StoredScanReport(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileHash: fileHash ?? this.fileHash,
      scanDate: scanDate ?? this.scanDate,
      positives: positives ?? this.positives,
      total: total ?? this.total,
      riskLevel: riskLevel ?? this.riskLevel,
      detectedThreats: detectedThreats ?? this.detectedThreats,
      permalink: permalink ?? this.permalink,
      userAcceptedRisk: userAcceptedRisk ?? this.userAcceptedRisk,
    );
  }

  bool get isClean => positives == 0;
  bool get isSuspicious => positives > 0 && positives <= 3;
  bool get isMalicious => positives > 3;
  
  double get detectionRate => total > 0 ? (positives / total) * 100 : 0.0;
}