import 'package:dio/dio.dart';
import '../models/package_info.dart';
import '../models/package_source.dart';
import 'system_detector.dart';

class GitHubService {
  final Dio _dio = Dio();

  GitHubService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.headers = {
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'PackageArmor/1.0.0',
    };
  }

  /// Search for GitHub repositories
  Future<List<GitHubRepository>> searchRepositories(String query, {int page = 1, int perPage = 30}) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/search/repositories',
        queryParameters: {
          'q': query,
          'sort': 'stars',
          'order': 'desc',
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final items = data['items'] as List;
        
        return items.map((item) => GitHubRepository.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      throw GitHubException('Failed to search repositories: $e');
    }
  }

  /// Get repository releases
  Future<List<GitHubRelease>> getRepositoryReleases(String owner, String repo) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$owner/$repo/releases',
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((item) => GitHubRelease.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      throw GitHubException('Failed to get releases: $e');
    }
  }

  /// Get the latest release for a repository
  Future<GitHubRelease?> getLatestRelease(String owner, String repo) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );

      if (response.statusCode == 200) {
        return GitHubRelease.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      // Repository might not have releases
      return null;
    }
  }

  /// Get repository information
  Future<GitHubRepository?> getRepository(String owner, String repo) async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$owner/$repo',
      );

      if (response.statusCode == 200) {
        return GitHubRepository.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      throw GitHubException('Failed to get repository: $e');
    }
  }

  /// Find the best asset for the current system
  Future<GitHubAsset?> findBestAssetForSystem(List<GitHubAsset> assets) async {
    final architecture = await SystemDetector.getArchitecture();

    // Priority list for Linux packages
    final priorities = <String, int>{
      '.deb': 10,
      '.appimage': 9,
      '.tar.gz': 8,
      '.tar.xz': 7,
      '.rpm': 6,
      '.pkg.tar.xz': 5,
      '.snap': 4,
      '.flatpak': 3,
      '.zip': 2,
      '.tar': 1,
    };

    // Architecture keywords to look for
    final archKeywords = <String, List<String>>{
      'x86_64': ['x86_64', 'amd64', 'x64', '64bit'],
      'aarch64': ['aarch64', 'arm64', 'armv8'],
      'armv7l': ['armv7', 'armhf', 'arm32'],
      'i386': ['i386', 'i686', '32bit', 'x86'],
    };

    GitHubAsset? bestAsset;
    int bestScore = -1;

    for (final asset in assets) {
      final name = asset.name.toLowerCase();
      int score = 0;

      // Check file extension priority
      for (final ext in priorities.keys) {
        if (name.endsWith(ext)) {
          score += priorities[ext]!;
          break;
        }
      }

      // Check architecture compatibility
      final currentArchKeywords = archKeywords[architecture] ?? [];
      for (final keyword in currentArchKeywords) {
        if (name.contains(keyword)) {
          score += 20; // High bonus for architecture match
          break;
        }
      }

      // Check for Linux compatibility
      if (name.contains('linux')) {
        score += 15;
      }

      // Penalize Windows/Mac specific files
      if (name.contains('windows') || name.contains('win') || 
          name.contains('macos') || name.contains('darwin') ||
          name.endsWith('.exe') || name.endsWith('.msi') ||
          name.endsWith('.dmg')) {
        score -= 50;
      }

      // Prefer non-source archives
      if (!name.contains('source') && !name.contains('src')) {
        score += 5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestAsset = asset;
      }
    }

    return bestAsset;
  }

  /// Convert GitHub repository to PackageInfo
  Future<PackageInfo> repositoryToPackageInfo(GitHubRepository repo, {GitHubRelease? release}) async {
    final asset = release != null ? await findBestAssetForSystem(release.assets) : null;
    
    return PackageInfo(
      name: repo.name,
      version: release?.tagName ?? 'latest',
      description: repo.description ?? 'GitHub repository',
      homepage: repo.htmlUrl,
      maintainer: repo.owner.login,
      source: PackageSource.github,
      downloadUrl: asset?.browserDownloadUrl ?? repo.archiveUrl,
      rating: repo.stargazersCount > 0 ? (repo.stargazersCount / 1000).clamp(0.0, 5.0) : null,
      downloads: release?.assets.fold<int>(0, (sum, asset) => sum + asset.downloadCount),
      lastUpdated: release?.publishedAt ?? repo.updatedAt,
    );
  }
}

class GitHubRepository {
  final int id;
  final String name;
  final String fullName;
  final GitHubUser owner;
  final String? description;
  final String htmlUrl;
  final String archiveUrl;
  final int stargazersCount;
  final int forksCount;
  final String? language;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? license;

  GitHubRepository({
    required this.id,
    required this.name,
    required this.fullName,
    required this.owner,
    this.description,
    required this.htmlUrl,
    required this.archiveUrl,
    required this.stargazersCount,
    required this.forksCount,
    this.language,
    required this.createdAt,
    required this.updatedAt,
    this.license,
  });

  factory GitHubRepository.fromJson(Map<String, dynamic> json) {
    return GitHubRepository(
      id: json['id'],
      name: json['name'],
      fullName: json['full_name'],
      owner: GitHubUser.fromJson(json['owner']),
      description: json['description'],
      htmlUrl: json['html_url'],
      archiveUrl: '${json['html_url']}/archive/refs/heads/${json['default_branch'] ?? 'main'}.tar.gz',
      stargazersCount: json['stargazers_count'] ?? 0,
      forksCount: json['forks_count'] ?? 0,
      language: json['language'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      license: json['license']?['name'],
    );
  }
}

class GitHubUser {
  final int id;
  final String login;
  final String avatarUrl;
  final String htmlUrl;

  GitHubUser({
    required this.id,
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
  });

  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      id: json['id'],
      login: json['login'],
      avatarUrl: json['avatar_url'],
      htmlUrl: json['html_url'],
    );
  }
}

class GitHubRelease {
  final int id;
  final String tagName;
  final String name;
  final String? body;
  final bool prerelease;
  final DateTime publishedAt;
  final List<GitHubAsset> assets;

  GitHubRelease({
    required this.id,
    required this.tagName,
    required this.name,
    this.body,
    required this.prerelease,
    required this.publishedAt,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assetsData = json['assets'] as List? ?? [];
    final assets = assetsData.map((asset) => GitHubAsset.fromJson(asset)).toList();

    return GitHubRelease(
      id: json['id'],
      tagName: json['tag_name'],
      name: json['name'] ?? json['tag_name'],
      body: json['body'],
      prerelease: json['prerelease'] ?? false,
      publishedAt: DateTime.parse(json['published_at']),
      assets: assets,
    );
  }
}

class GitHubAsset {
  final int id;
  final String name;
  final String contentType;
  final int size;
  final int downloadCount;
  final String browserDownloadUrl;

  GitHubAsset({
    required this.id,
    required this.name,
    required this.contentType,
    required this.size,
    required this.downloadCount,
    required this.browserDownloadUrl,
  });

  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      id: json['id'],
      name: json['name'],
      contentType: json['content_type'] ?? '',
      size: json['size'] ?? 0,
      downloadCount: json['download_count'] ?? 0,
      browserDownloadUrl: json['browser_download_url'],
    );
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class GitHubException implements Exception {
  final String message;
  
  GitHubException(this.message);
  
  @override
  String toString() => 'GitHubException: $message';
}