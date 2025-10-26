import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Example providers for your package manager app

// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

// Provider for app settings
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.read(sharedPreferencesProvider));
});

// App settings model
class AppSettings {
  final bool autoUpdatePackageList;
  final bool confirmBeforeInstall;
  final bool showSystemPackages;
  final bool enableNotifications;
  final bool enableVirusScanning;
  final String defaultPackageManager;

  const AppSettings({
    this.autoUpdatePackageList = true,
    this.confirmBeforeInstall = true,
    this.showSystemPackages = false,
    this.enableNotifications = true,
    this.enableVirusScanning = true,
    this.defaultPackageManager = 'apt',
  });

  AppSettings copyWith({
    bool? autoUpdatePackageList,
    bool? confirmBeforeInstall,
    bool? showSystemPackages,
    bool? enableNotifications,
    bool? enableVirusScanning,
    String? defaultPackageManager,
  }) {
    return AppSettings(
      autoUpdatePackageList:
          autoUpdatePackageList ?? this.autoUpdatePackageList,
      confirmBeforeInstall: confirmBeforeInstall ?? this.confirmBeforeInstall,
      showSystemPackages: showSystemPackages ?? this.showSystemPackages,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableVirusScanning: enableVirusScanning ?? this.enableVirusScanning,
      defaultPackageManager:
          defaultPackageManager ?? this.defaultPackageManager,
    );
  }
}

// App settings notifier
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = AppSettings(
      autoUpdatePackageList: _prefs.getBool('auto_update_package_list') ?? true,
      confirmBeforeInstall: _prefs.getBool('confirm_before_install') ?? true,
      showSystemPackages: _prefs.getBool('show_system_packages') ?? false,
      enableNotifications: _prefs.getBool('enable_notifications') ?? true,
      enableVirusScanning: _prefs.getBool('enable_virus_scanning') ?? true,
      defaultPackageManager:
          _prefs.getString('default_package_manager') ?? 'apt',
    );
  }

  Future<void> updateAutoUpdatePackageList(bool value) async {
    await _prefs.setBool('auto_update_package_list', value);
    state = state.copyWith(autoUpdatePackageList: value);
  }

  Future<void> updateConfirmBeforeInstall(bool value) async {
    await _prefs.setBool('confirm_before_install', value);
    state = state.copyWith(confirmBeforeInstall: value);
  }

  Future<void> updateShowSystemPackages(bool value) async {
    await _prefs.setBool('show_system_packages', value);
    state = state.copyWith(showSystemPackages: value);
  }

  Future<void> updateEnableNotifications(bool value) async {
    await _prefs.setBool('enable_notifications', value);
    state = state.copyWith(enableNotifications: value);
  }

  Future<void> updateEnableVirusScanning(bool value) async {
    await _prefs.setBool('enable_virus_scanning', value);
    state = state.copyWith(enableVirusScanning: value);
  }

  Future<void> updateDefaultPackageManager(String value) async {
    await _prefs.setString('default_package_manager', value);
    state = state.copyWith(defaultPackageManager: value);
  }
}

// Example provider for package list state
final packageListProvider =
    StateNotifierProvider<PackageListNotifier, PackageListState>((ref) {
  return PackageListNotifier();
});

// Package list state
class PackageListState {
  final List<String> packages;
  final bool isLoading;
  final String? error;

  const PackageListState({
    this.packages = const [],
    this.isLoading = false,
    this.error,
  });

  PackageListState copyWith({
    List<String>? packages,
    bool? isLoading,
    String? error,
  }) {
    return PackageListState(
      packages: packages ?? this.packages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Package list notifier
class PackageListNotifier extends StateNotifier<PackageListState> {
  PackageListNotifier() : super(const PackageListState());

  Future<void> loadPackages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate loading packages
      await Future.delayed(const Duration(seconds: 2));
      final packages = [
        'package1',
        'package2',
        'package3'
      ]; // Replace with actual logic
      state = state.copyWith(packages: packages, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
