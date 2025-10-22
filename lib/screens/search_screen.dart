import 'package:flutter/material.dart';
import '../models/package_info.dart';
import '../models/package_source.dart';
import '../services/package_search.dart';
import '../services/package_installer.dart';
import '../services/system_detector.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PackageSearchService _searchService = PackageSearchService();
  final PackageInstaller _installer = PackageInstaller();
  
  List<PackageInfo> _searchResults = [];
  bool _isSearching = false;
  List<String> _availableManagers = [];
  final Set<PackageSource> _selectedSources = {PackageSource.apt};
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableManagers();
  }

  Future<void> _loadAvailableManagers() async {
    final managers = await SystemDetector.getAvailablePackageManagers();
    setState(() {
      _availableManagers = managers;
      _selectedSources.clear();
      
      // Auto-select available sources
      if (managers.contains('apt')) _selectedSources.add(PackageSource.apt);
      if (managers.contains('snap')) _selectedSources.add(PackageSource.snap);
      if (managers.contains('flatpak')) _selectedSources.add(PackageSource.flatpak);
    });
  }

  Future<void> _searchPackages(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _lastQuery = query;
      _searchResults.clear();
    });

    final List<Future<List<PackageInfo>>> searchFutures = [];

    if (_selectedSources.contains(PackageSource.apt) && _availableManagers.contains('apt')) {
      searchFutures.add(_searchService.searchAptPackages(query));
    }
    
    if (_selectedSources.contains(PackageSource.snap) && _availableManagers.contains('snap')) {
      searchFutures.add(_searchService.searchSnapPackages(query));
    }
    
    if (_selectedSources.contains(PackageSource.flatpak) && _availableManagers.contains('flatpak')) {
      searchFutures.add(_searchService.searchFlatpakPackages(query));
    }

    if (_selectedSources.contains(PackageSource.github)) {
      // For GitHub, assume the query is a repo name
      if (query.contains('/')) {
        searchFutures.add(_searchService.searchGitHubReleases(query));
      }
    }

    try {
      final results = await Future.wait(searchFutures);
      final allPackages = <PackageInfo>[];
      
      for (var packageList in results) {
        allPackages.addAll(packageList);
      }

      setState(() {
        _searchResults = allPackages;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorDialog('Search failed: $e');
    }
  }

  Future<void> _installPackage(PackageInfo package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${package.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${package.version}'),
            if (package.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Description: ${package.description}'),
            ],
            if (package.size != null) ...[
              const SizedBox(height: 8),
              Text('Size: ${package.formattedSize}'),
            ],
            const SizedBox(height: 16),
            Text('Source: ${package.source.displayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Install'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showInstallationDialog(package);
    }
  }

  void _showInstallationDialog(PackageInfo package) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InstallationProgressDialog(
        package: package,
        installer: _installer,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header section with search and filters
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover Packages',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search and install packages from multiple sources',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search packages... (e.g., "firefox" or "user/repo" for GitHub)',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults.clear();
                                  _lastQuery = '';
                                });
                              },
                            )
                          : null,
                ),
                onSubmitted: _searchPackages,
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to show/hide clear button
                },
              ),
              
              const SizedBox(height: 20),
              
              // Source filters
              if (_availableManagers.isNotEmpty) ...[
                Text(
                  'Package Sources',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_availableManagers.contains('apt'))
                      _buildSourceChip(
                        PackageSource.apt,
                        '${PackageSource.apt.icon} APT',
                        Colors.orange,
                      ),
                    if (_availableManagers.contains('snap'))
                      _buildSourceChip(
                        PackageSource.snap,
                        '${PackageSource.snap.icon} Snap',
                        Colors.green,
                      ),
                    if (_availableManagers.contains('flatpak'))
                      _buildSourceChip(
                        PackageSource.flatpak,
                        '${PackageSource.flatpak.icon} Flatpak',
                        Colors.blue,
                      ),
                    _buildSourceChip(
                      PackageSource.github,
                      '${PackageSource.github.icon} GitHub',
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Search results
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSourceChip(PackageSource source, String label, Color color) {
    final isSelected = _selectedSources.contains(source);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedSources.add(source);
          } else {
            _selectedSources.remove(source);
          }
        });
      },
      backgroundColor: color.withValues(alpha: 0.1),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _lastQuery.isNotEmpty && !_isSearching) {
      return _buildEmptyState();
    }
    
    if (_searchResults.isEmpty && _lastQuery.isEmpty) {
      return _buildWelcomeState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final package = _searchResults[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start Discovering',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for packages across multiple sources\nto find exactly what you need',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No packages found for "$_lastQuery"\nTry different keywords or check your sources',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PackageInfo package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSourceColor(package.source).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    package.source.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSourceColor(package.source).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getSourceColor(package.source).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              package.source.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getSourceColor(package.source),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'v${package.version}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          if (package.size != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${package.formattedSize}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _installPackage(package),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Install'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _getSourceColor(package.source),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (package.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                package.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSourceColor(PackageSource source) {
    switch (source) {
      case PackageSource.apt:
        return Colors.orange;
      case PackageSource.snap:
        return Colors.green;
      case PackageSource.flatpak:
        return Colors.blue;
      case PackageSource.github:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class InstallationProgressDialog extends StatefulWidget {
  final PackageInfo package;
  final PackageInstaller installer;

  const InstallationProgressDialog({
    super.key,
    required this.package,
    required this.installer,
  });

  @override
  State<InstallationProgressDialog> createState() => _InstallationProgressDialogState();
}

class _InstallationProgressDialogState extends State<InstallationProgressDialog> {
  String _status = 'Preparing installation...';
  String _output = '';
  bool _isComplete = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _startInstallation();
  }

  Future<void> _startInstallation() async {
    setState(() {
      _status = 'Installing ${widget.package.name}...';
    });

    try {
      final result = await widget.installer.installFromPackageInfo(widget.package);
      
      setState(() {
        _isComplete = true;
        _success = result.success;
        _status = result.success ? 'Installation completed!' : 'Installation failed';
        _output = result.output;
      });
    } catch (e) {
      setState(() {
        _isComplete = true;
        _success = false;
        _status = 'Installation failed';
        _output = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (!_isComplete)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _success ? Icons.check_circle : Icons.error,
              color: _success ? Colors.green : Colors.red,
            ),
          const SizedBox(width: 8),
          Expanded(child: Text(_status)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: SingleChildScrollView(
          child: Text(
            _output.isEmpty ? 'Please wait...' : _output,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
      actions: [
        if (_isComplete)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}