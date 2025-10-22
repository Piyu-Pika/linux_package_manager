class InstallationResult {
  final bool success;
  final String output;
  final String error;
  final String? packageName;
  final String? version;
  final Duration? installTime;

  InstallationResult({
    required this.success,
    required this.output,
    this.error = '',
    this.packageName,
    this.version,
    this.installTime,
  });
}
