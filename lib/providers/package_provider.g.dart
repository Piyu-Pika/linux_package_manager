// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appVersionHash() => r'0c30e6c7150456c44f403b85070b580ece180d49';

/// See also [appVersion].
@ProviderFor(appVersion)
final appVersionProvider = AutoDisposeProvider<String>.internal(
  appVersion,
  name: r'appVersionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppVersionRef = AutoDisposeProviderRef<String>;
String _$packageManagerHash() => r'36aa227d56deccf48eb1acf6c2f9d164485c6ecc';

/// See also [packageManager].
@ProviderFor(packageManager)
final packageManagerProvider = AutoDisposeProvider<PackageManager>.internal(
  packageManager,
  name: r'packageManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$packageManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PackageManagerRef = AutoDisposeProviderRef<PackageManager>;
String _$gitHubServiceHash() => r'32ebfc91263193863853da2035181fc35c8d9a04';

/// See also [gitHubService].
@ProviderFor(gitHubService)
final gitHubServiceProvider = AutoDisposeProvider<GitHubService>.internal(
  gitHubService,
  name: r'gitHubServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gitHubServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GitHubServiceRef = AutoDisposeProviderRef<GitHubService>;
String _$securityScannerServiceHash() =>
    r'c963c59125e1551ea569c0d3df31d7b1637960a5';

/// See also [securityScannerService].
@ProviderFor(securityScannerService)
final securityScannerServiceProvider =
    AutoDisposeProvider<SecurityScannerService>.internal(
  securityScannerService,
  name: r'securityScannerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$securityScannerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecurityScannerServiceRef
    = AutoDisposeProviderRef<SecurityScannerService>;
String _$scanReportManagerHash() => r'461a38db5c3c878bd64a17d190a320ea8ec38ef0';

/// See also [scanReportManager].
@ProviderFor(scanReportManager)
final scanReportManagerProvider =
    AutoDisposeProvider<ScanReportManager>.internal(
  scanReportManager,
  name: r'scanReportManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scanReportManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanReportManagerRef = AutoDisposeProviderRef<ScanReportManager>;
String _$installedPackagesHash() => r'994d464a85678bb1c90021f0af49621997ae2670';

/// See also [installedPackages].
@ProviderFor(installedPackages)
final installedPackagesProvider =
    AutoDisposeFutureProvider<List<InstalledPackage>>.internal(
  installedPackages,
  name: r'installedPackagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$installedPackagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InstalledPackagesRef
    = AutoDisposeFutureProviderRef<List<InstalledPackage>>;
String _$packageCountHash() => r'83010e3c31853141a56bcdaab6e49f289efd8dfa';

/// See also [packageCount].
@ProviderFor(packageCount)
final packageCountProvider = AutoDisposeFutureProvider<int>.internal(
  packageCount,
  name: r'packageCountProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$packageCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PackageCountRef = AutoDisposeFutureProviderRef<int>;
String _$isPackageInstalledHash() =>
    r'7fcba65cc6c93047be6c57e8e97be94f078b8819';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [isPackageInstalled].
@ProviderFor(isPackageInstalled)
const isPackageInstalledProvider = IsPackageInstalledFamily();

/// See also [isPackageInstalled].
class IsPackageInstalledFamily extends Family<AsyncValue<bool>> {
  /// See also [isPackageInstalled].
  const IsPackageInstalledFamily();

  /// See also [isPackageInstalled].
  IsPackageInstalledProvider call(
    String packageName,
  ) {
    return IsPackageInstalledProvider(
      packageName,
    );
  }

  @override
  IsPackageInstalledProvider getProviderOverride(
    covariant IsPackageInstalledProvider provider,
  ) {
    return call(
      provider.packageName,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isPackageInstalledProvider';
}

/// See also [isPackageInstalled].
class IsPackageInstalledProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isPackageInstalled].
  IsPackageInstalledProvider(
    String packageName,
  ) : this._internal(
          (ref) => isPackageInstalled(
            ref as IsPackageInstalledRef,
            packageName,
          ),
          from: isPackageInstalledProvider,
          name: r'isPackageInstalledProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isPackageInstalledHash,
          dependencies: IsPackageInstalledFamily._dependencies,
          allTransitiveDependencies:
              IsPackageInstalledFamily._allTransitiveDependencies,
          packageName: packageName,
        );

  IsPackageInstalledProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.packageName,
  }) : super.internal();

  final String packageName;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsPackageInstalledRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsPackageInstalledProvider._internal(
        (ref) => create(ref as IsPackageInstalledRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        packageName: packageName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsPackageInstalledProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsPackageInstalledProvider &&
        other.packageName == packageName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, packageName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsPackageInstalledRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `packageName` of this provider.
  String get packageName;
}

class _IsPackageInstalledProviderElement
    extends AutoDisposeFutureProviderElement<bool> with IsPackageInstalledRef {
  _IsPackageInstalledProviderElement(super.provider);

  @override
  String get packageName => (origin as IsPackageInstalledProvider).packageName;
}

String _$availableUpdatesHash() => r'aa831641d7fce9f077999a2377ed9a7d7265b620';

/// See also [availableUpdates].
@ProviderFor(availableUpdates)
const availableUpdatesProvider = AvailableUpdatesFamily();

/// See also [availableUpdates].
class AvailableUpdatesFamily extends Family<AsyncValue<List<String>>> {
  /// See also [availableUpdates].
  const AvailableUpdatesFamily();

  /// See also [availableUpdates].
  AvailableUpdatesProvider call({
    String source = 'apt',
  }) {
    return AvailableUpdatesProvider(
      source: source,
    );
  }

  @override
  AvailableUpdatesProvider getProviderOverride(
    covariant AvailableUpdatesProvider provider,
  ) {
    return call(
      source: provider.source,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'availableUpdatesProvider';
}

/// See also [availableUpdates].
class AvailableUpdatesProvider extends AutoDisposeFutureProvider<List<String>> {
  /// See also [availableUpdates].
  AvailableUpdatesProvider({
    String source = 'apt',
  }) : this._internal(
          (ref) => availableUpdates(
            ref as AvailableUpdatesRef,
            source: source,
          ),
          from: availableUpdatesProvider,
          name: r'availableUpdatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$availableUpdatesHash,
          dependencies: AvailableUpdatesFamily._dependencies,
          allTransitiveDependencies:
              AvailableUpdatesFamily._allTransitiveDependencies,
          source: source,
        );

  AvailableUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.source,
  }) : super.internal();

  final String source;

  @override
  Override overrideWith(
    FutureOr<List<String>> Function(AvailableUpdatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvailableUpdatesProvider._internal(
        (ref) => create(ref as AvailableUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        source: source,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<String>> createElement() {
    return _AvailableUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableUpdatesProvider && other.source == source;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, source.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AvailableUpdatesRef on AutoDisposeFutureProviderRef<List<String>> {
  /// The parameter `source` of this provider.
  String get source;
}

class _AvailableUpdatesProviderElement
    extends AutoDisposeFutureProviderElement<List<String>>
    with AvailableUpdatesRef {
  _AvailableUpdatesProviderElement(super.provider);

  @override
  String get source => (origin as AvailableUpdatesProvider).source;
}

String _$packageDetailsHash() => r'10c22b367e58473acc0d5c22864d76a0b1bde651';

/// See also [packageDetails].
@ProviderFor(packageDetails)
const packageDetailsProvider = PackageDetailsFamily();

/// See also [packageDetails].
class PackageDetailsFamily extends Family<AsyncValue<PackageInfo?>> {
  /// See also [packageDetails].
  const PackageDetailsFamily();

  /// See also [packageDetails].
  PackageDetailsProvider call(
    String packageName, {
    String source = 'apt',
  }) {
    return PackageDetailsProvider(
      packageName,
      source: source,
    );
  }

  @override
  PackageDetailsProvider getProviderOverride(
    covariant PackageDetailsProvider provider,
  ) {
    return call(
      provider.packageName,
      source: provider.source,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'packageDetailsProvider';
}

/// See also [packageDetails].
class PackageDetailsProvider extends AutoDisposeFutureProvider<PackageInfo?> {
  /// See also [packageDetails].
  PackageDetailsProvider(
    String packageName, {
    String source = 'apt',
  }) : this._internal(
          (ref) => packageDetails(
            ref as PackageDetailsRef,
            packageName,
            source: source,
          ),
          from: packageDetailsProvider,
          name: r'packageDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$packageDetailsHash,
          dependencies: PackageDetailsFamily._dependencies,
          allTransitiveDependencies:
              PackageDetailsFamily._allTransitiveDependencies,
          packageName: packageName,
          source: source,
        );

  PackageDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.packageName,
    required this.source,
  }) : super.internal();

  final String packageName;
  final String source;

  @override
  Override overrideWith(
    FutureOr<PackageInfo?> Function(PackageDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PackageDetailsProvider._internal(
        (ref) => create(ref as PackageDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        packageName: packageName,
        source: source,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PackageInfo?> createElement() {
    return _PackageDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PackageDetailsProvider &&
        other.packageName == packageName &&
        other.source == source;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, packageName.hashCode);
    hash = _SystemHash.combine(hash, source.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PackageDetailsRef on AutoDisposeFutureProviderRef<PackageInfo?> {
  /// The parameter `packageName` of this provider.
  String get packageName;

  /// The parameter `source` of this provider.
  String get source;
}

class _PackageDetailsProviderElement
    extends AutoDisposeFutureProviderElement<PackageInfo?>
    with PackageDetailsRef {
  _PackageDetailsProviderElement(super.provider);

  @override
  String get packageName => (origin as PackageDetailsProvider).packageName;
  @override
  String get source => (origin as PackageDetailsProvider).source;
}

String _$gitHubSearchHash() => r'08523426c5edaa77b536fe469a93f69d0a21ad60';

/// See also [gitHubSearch].
@ProviderFor(gitHubSearch)
const gitHubSearchProvider = GitHubSearchFamily();

/// See also [gitHubSearch].
class GitHubSearchFamily extends Family<AsyncValue<List<GitHubRepository>>> {
  /// See also [gitHubSearch].
  const GitHubSearchFamily();

  /// See also [gitHubSearch].
  GitHubSearchProvider call(
    String query, {
    int page = 1,
  }) {
    return GitHubSearchProvider(
      query,
      page: page,
    );
  }

  @override
  GitHubSearchProvider getProviderOverride(
    covariant GitHubSearchProvider provider,
  ) {
    return call(
      provider.query,
      page: provider.page,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'gitHubSearchProvider';
}

/// See also [gitHubSearch].
class GitHubSearchProvider
    extends AutoDisposeFutureProvider<List<GitHubRepository>> {
  /// See also [gitHubSearch].
  GitHubSearchProvider(
    String query, {
    int page = 1,
  }) : this._internal(
          (ref) => gitHubSearch(
            ref as GitHubSearchRef,
            query,
            page: page,
          ),
          from: gitHubSearchProvider,
          name: r'gitHubSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$gitHubSearchHash,
          dependencies: GitHubSearchFamily._dependencies,
          allTransitiveDependencies:
              GitHubSearchFamily._allTransitiveDependencies,
          query: query,
          page: page,
        );

  GitHubSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.page,
  }) : super.internal();

  final String query;
  final int page;

  @override
  Override overrideWith(
    FutureOr<List<GitHubRepository>> Function(GitHubSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GitHubSearchProvider._internal(
        (ref) => create(ref as GitHubSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GitHubRepository>> createElement() {
    return _GitHubSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GitHubSearchProvider &&
        other.query == query &&
        other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GitHubSearchRef on AutoDisposeFutureProviderRef<List<GitHubRepository>> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `page` of this provider.
  int get page;
}

class _GitHubSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<GitHubRepository>>
    with GitHubSearchRef {
  _GitHubSearchProviderElement(super.provider);

  @override
  String get query => (origin as GitHubSearchProvider).query;
  @override
  int get page => (origin as GitHubSearchProvider).page;
}

String _$gitHubReleasesHash() => r'849bf2febc2885ab91d266202bd4e340b77192f5';

/// See also [gitHubReleases].
@ProviderFor(gitHubReleases)
const gitHubReleasesProvider = GitHubReleasesFamily();

/// See also [gitHubReleases].
class GitHubReleasesFamily extends Family<AsyncValue<List<GitHubRelease>>> {
  /// See also [gitHubReleases].
  const GitHubReleasesFamily();

  /// See also [gitHubReleases].
  GitHubReleasesProvider call(
    String owner,
    String repo,
  ) {
    return GitHubReleasesProvider(
      owner,
      repo,
    );
  }

  @override
  GitHubReleasesProvider getProviderOverride(
    covariant GitHubReleasesProvider provider,
  ) {
    return call(
      provider.owner,
      provider.repo,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'gitHubReleasesProvider';
}

/// See also [gitHubReleases].
class GitHubReleasesProvider
    extends AutoDisposeFutureProvider<List<GitHubRelease>> {
  /// See also [gitHubReleases].
  GitHubReleasesProvider(
    String owner,
    String repo,
  ) : this._internal(
          (ref) => gitHubReleases(
            ref as GitHubReleasesRef,
            owner,
            repo,
          ),
          from: gitHubReleasesProvider,
          name: r'gitHubReleasesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$gitHubReleasesHash,
          dependencies: GitHubReleasesFamily._dependencies,
          allTransitiveDependencies:
              GitHubReleasesFamily._allTransitiveDependencies,
          owner: owner,
          repo: repo,
        );

  GitHubReleasesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.owner,
    required this.repo,
  }) : super.internal();

  final String owner;
  final String repo;

  @override
  Override overrideWith(
    FutureOr<List<GitHubRelease>> Function(GitHubReleasesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GitHubReleasesProvider._internal(
        (ref) => create(ref as GitHubReleasesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        owner: owner,
        repo: repo,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GitHubRelease>> createElement() {
    return _GitHubReleasesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GitHubReleasesProvider &&
        other.owner == owner &&
        other.repo == repo;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, owner.hashCode);
    hash = _SystemHash.combine(hash, repo.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GitHubReleasesRef on AutoDisposeFutureProviderRef<List<GitHubRelease>> {
  /// The parameter `owner` of this provider.
  String get owner;

  /// The parameter `repo` of this provider.
  String get repo;
}

class _GitHubReleasesProviderElement
    extends AutoDisposeFutureProviderElement<List<GitHubRelease>>
    with GitHubReleasesRef {
  _GitHubReleasesProviderElement(super.provider);

  @override
  String get owner => (origin as GitHubReleasesProvider).owner;
  @override
  String get repo => (origin as GitHubReleasesProvider).repo;
}

String _$scanReportsHash() => r'142a37f9c7c0b1fbe012f7d8defa17943011bf5a';

/// See also [scanReports].
@ProviderFor(scanReports)
final scanReportsProvider =
    AutoDisposeFutureProvider<List<StoredScanReport>>.internal(
  scanReports,
  name: r'scanReportsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scanReportsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanReportsRef = AutoDisposeFutureProviderRef<List<StoredScanReport>>;
String _$packageSearchHash() => r'0f0a35fa8f5c59670072e9efe558b3c980f0fb73';

/// See also [PackageSearch].
@ProviderFor(PackageSearch)
final packageSearchProvider =
    AutoDisposeNotifierProvider<PackageSearch, PackageSearchState>.internal(
  PackageSearch.new,
  name: r'packageSearchProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$packageSearchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PackageSearch = AutoDisposeNotifier<PackageSearchState>;
String _$installationStateHash() => r'83e086dfbec4bae2db941aaaef59838981aec717';

/// See also [InstallationState].
@ProviderFor(InstallationState)
final installationStateProvider = AutoDisposeNotifierProvider<InstallationState,
    InstallationStateData>.internal(
  InstallationState.new,
  name: r'installationStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$installationStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InstallationState = AutoDisposeNotifier<InstallationStateData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
