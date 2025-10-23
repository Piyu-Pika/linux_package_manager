import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/installed_package.dart';
import '../models/package_info.dart';
import '../models/scan_report.dart';
import '../services/package_manager.dart';
import '../services/github_service.dart';
import '../services/scan_report_manager.dart';
import '../services/security_scanner_service.dart';

// This will generate the provider code when you run build_runner
part 'package_provider.g.dart';

// App version provider
@riverpod
String appVersion(Ref ref) {
  return '1.0.0';
}

// Package Manager Service Provider
@riverpod
PackageManager packageManager(Ref ref) {
  return PackageManager();
}

// GitHub Service Provider
@riverpod
GitHubService gitHubService(Ref ref) {
  return GitHubService();
}

// Security Scanner Service Provider
@riverpod
SecurityScannerService securityScannerService(Ref ref) {
  return SecurityScannerService();
}

// Scan Report Manager Provider
@riverpod
ScanReportManager scanReportManager(Ref ref) {
  return ScanReportManager();
}

// Installed packages provider
@riverpod
Future<List<InstalledPackage>> installedPackages(Ref ref) async {
  final packageManager = ref.watch(packageManagerProvider);
  return await packageManager.getInstalledPackages();
}

// Package count provider
@riverpod
Future<int> packageCount(Ref ref) async {
  final packages = await ref.watch(installedPackagesProvider.future);
  return packages.length;
}

// Check if package is installed
@riverpod
Future<bool> isPackageInstalled(Ref ref, String packageName) async {
  final packages = await ref.watch(installedPackagesProvider.future);
  return packages.any((pkg) => pkg.name == packageName);
}

// Available updates provider
@riverpod
Future<List<String>> availableUpdates(Ref ref, {String source = 'apt'}) async {
  final packageManager = ref.watch(packageManagerProvider);
  return await packageManager.getAvailableUpdates(source: source);
}

// Package details provider
@riverpod
Future<PackageInfo?> packageDetails(Ref ref, String packageName, {String source = 'apt'}) async {
  final packageManager = ref.watch(packageManagerProvider);
  return await packageManager.getPackageDetails(packageName, source: source);
}

// GitHub search provider
@riverpod
Future<List<GitHubRepository>> gitHubSearch(Ref ref, String query, {int page = 1}) async {
  if (query.isEmpty) return [];
  
  final gitHubService = ref.watch(gitHubServiceProvider);
  return await gitHubService.searchRepositories(query, page: page);
}

// GitHub repository releases provider
@riverpod
Future<List<GitHubRelease>> gitHubReleases(Ref ref, String owner, String repo) async {
  final gitHubService = ref.watch(gitHubServiceProvider);
  return await gitHubService.getRepositoryReleases(owner, repo);
}

// Scan reports provider
@riverpod
Future<List<StoredScanReport>> scanReports(Ref ref) async {
  final scanReportManager = ref.watch(scanReportManagerProvider);
  return await scanReportManager.getAllScanReports();
}

// Package search state provider
@riverpod
class PackageSearch extends _$PackageSearch {
  @override
  PackageSearchState build() {
    return const PackageSearchState();
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _performSearch();
  }

  void _performSearch() async {
    if (state.query.isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Search GitHub repositories
      final gitHubService = ref.read(gitHubServiceProvider);
      final repositories = await gitHubService.searchRepositories(state.query);
      
      final results = <PackageInfo>[];
      for (final repo in repositories) {
        final packageInfo = await gitHubService.repositoryToPackageInfo(repo);
        results.add(packageInfo);
      }

      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(results: [], isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = const PackageSearchState();
  }
}

// Installation state provider
@riverpod
class InstallationState extends _$InstallationState {
  @override
  InstallationStateData build() {
    return const InstallationStateData();
  }

  void startInstallation(String packageName) {
    state = state.copyWith(
      isInstalling: true,
      currentPackage: packageName,
      progress: 0.0,
      error: null,
    );
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void completeInstallation({String? error}) {
    state = state.copyWith(
      isInstalling: false,
      currentPackage: null,
      progress: 1.0,
      error: error,
    );
    
    // Refresh installed packages
    ref.invalidate(installedPackagesProvider);
  }
}

// State classes
class PackageSearchState {
  final String query;
  final List<PackageInfo> results;
  final bool isLoading;
  final String? error;

  const PackageSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  PackageSearchState copyWith({
    String? query,
    List<PackageInfo>? results,
    bool? isLoading,
    String? error,
  }) {
    return PackageSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class InstallationStateData {
  final bool isInstalling;
  final String? currentPackage;
  final double progress;
  final String? error;

  const InstallationStateData({
    this.isInstalling = false,
    this.currentPackage,
    this.progress = 0.0,
    this.error,
  });

  InstallationStateData copyWith({
    bool? isInstalling,
    String? currentPackage,
    double? progress,
    String? error,
  }) {
    return InstallationStateData(
      isInstalling: isInstalling ?? this.isInstalling,
      currentPackage: currentPackage ?? this.currentPackage,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}
