import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/package_info.dart';
import '../models/package_source.dart';

class PackageSearchService {
  Future<List<PackageInfo>> searchAptPackages(String query) async {
    try {
      final result = await Process.run('apt', ['search', query]);
      if (result.exitCode != 0) return [];

      final packages = <PackageInfo>[];
      final lines = result.stdout.toString().split('\n');
      
      for (var line in lines) {
        if (line.trim().isEmpty || line.startsWith('WARNING')) continue;
        
        final match = RegExp(r'^([^/]+)/[^\s]+ ([^\s]+) (.+)$').firstMatch(line);
        if (match != null) {
          packages.add(PackageInfo(
            name: match.group(1)!,
            version: match.group(2)!,
            description: match.group(3)!,
            source: PackageSource.apt,
          ));
        }
      }
      
      return packages;
    } catch (e) {
      return [];
    }
  }

  Future<List<PackageInfo>> searchSnapPackages(String query) async {
    try {
      final result = await Process.run('snap', ['find', query]);
      if (result.exitCode != 0) return [];

      final packages = <PackageInfo>[];
      final lines = result.stdout.toString().split('\n');
      
      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          packages.add(PackageInfo(
            name: parts[0],
            version: parts[1],
            description: parts.sublist(4).join(' '),
            source: PackageSource.snap,
          ));
        }
      }
      
      return packages;
    } catch (e) {
      return [];
    }
  }

  Future<List<PackageInfo>> searchFlatpakPackages(String query) async {
    try {
      final result = await Process.run('flatpak', ['search', query]);
      if (result.exitCode != 0) return [];

      final packages = <PackageInfo>[];
      final lines = result.stdout.toString().split('\n');
      
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        final parts = line.split('\t');
        if (parts.length >= 3) {
          packages.add(PackageInfo(
            name: parts[0].trim(),
            description: parts[1].trim(),
            version: parts.length > 2 ? parts[2].trim() : 'latest',
            source: PackageSource.flatpak,
          ));
        }
      }
      
      return packages;
    } catch (e) {
      return [];
    }
  }

  Future<List<PackageInfo>> searchGitHubReleases(String repo) async {
    try {
      final url = 'https://api.github.com/repos/$repo/releases';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) return [];
      
      final releases = json.decode(response.body) as List;
      final packages = <PackageInfo>[];
      
      for (var release in releases.take(10)) {
        final assets = release['assets'] as List;
        final linuxAssets = assets.where((asset) {
          final name = asset['name'].toString().toLowerCase();
          return name.contains('linux') || 
                 name.endsWith('.deb') || 
                 name.endsWith('.appimage') ||
                 name.endsWith('.tar.gz');
        }).toList();
        
        if (linuxAssets.isNotEmpty) {
          packages.add(PackageInfo(
            name: release['name'] ?? repo.split('/').last,
            version: release['tag_name'] ?? 'unknown',
            description: release['body'] ?? 'GitHub release',
            source: PackageSource.github,
            downloadUrl: linuxAssets.first['browser_download_url'],
            lastUpdated: DateTime.tryParse(release['published_at'] ?? ''),
            downloads: linuxAssets.first['download_count'],
          ));
        }
      }
      
      return packages;
    } catch (e) {
      return [];
    }
  }

  Future<PackageInfo?> getPackageDetails(String packageName, PackageSource source) async {
    switch (source) {
      case PackageSource.apt:
        return await _getAptPackageDetails(packageName);
      case PackageSource.snap:
        return await _getSnapPackageDetails(packageName);
      case PackageSource.flatpak:
        return await _getFlatpakPackageDetails(packageName);
      default:
        return null;
    }
  }

  Future<PackageInfo?> _getAptPackageDetails(String packageName) async {
    try {
      final result = await Process.run('apt', ['show', packageName]);
      if (result.exitCode == 0) {
        return PackageInfo.fromAptShow(result.stdout.toString());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PackageInfo?> _getSnapPackageDetails(String packageName) async {
    try {
      final result = await Process.run('snap', ['info', packageName]);
      if (result.exitCode != 0) return null;

      final lines = result.stdout.toString().split('\n');
      String name = packageName;
      String version = '';
      String description = '';
      String? publisher;
      
      for (var line in lines) {
        if (line.startsWith('name:')) {
          name = line.substring(5).trim();
        } else if (line.startsWith('version:')) {
          version = line.substring(8).trim();
        } else if (line.startsWith('summary:')) {
          description = line.substring(8).trim();
        } else if (line.startsWith('publisher:')) {
          publisher = line.substring(10).trim();
        }
      }

      return PackageInfo(
        name: name,
        version: version,
        description: description,
        maintainer: publisher,
        source: PackageSource.snap,
      );
    } catch (e) {
      return null;
    }
  }

  Future<PackageInfo?> _getFlatpakPackageDetails(String packageName) async {
    try {
      final result = await Process.run('flatpak', ['info', packageName]);
      if (result.exitCode != 0) return null;

      final lines = result.stdout.toString().split('\n');
      String name = packageName;
      String version = '';
      String description = '';
      
      for (var line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          
          switch (key) {
            case 'Name':
              name = value;
              break;
            case 'Version':
              version = value;
              break;
            case 'Description':
              description = value;
              break;
          }
        }
      }

      return PackageInfo(
        name: name,
        version: version,
        description: description,
        source: PackageSource.flatpak,
      );
    } catch (e) {
      return null;
    }
  }
}