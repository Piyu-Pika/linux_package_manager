import 'package:flutter/material.dart';
import '../services/package_manager.dart';
import '../models/installed_package.dart';

class InstalledAppsScreen extends StatefulWidget {
  const InstalledAppsScreen({super.key});

  @override
  State<InstalledAppsScreen> createState() => _InstalledAppsScreenState();
}

class _InstalledAppsScreenState extends State<InstalledAppsScreen> {
  final PackageManager _packageManager = PackageManager();
  List<InstalledPackage> _packages = [];
  List<InstalledPackage> _filteredPackages = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _showSystemApps = false;
  String _selectedSource = 'all';

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final packages = await _packageManager.getInstalledPackages();
      setState(() {
        _packages = packages;
        _filterPackages();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error loading packages: $e');
    }
  }

  void _filterPackages() {
    setState(() {
      _filteredPackages = _packages.where((package) {
        final matchesSearch = package.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            package.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        if (!_showSystemApps && package.isSystemPackage) {
          return false;
        }
        
        if (_selectedSource != 'all' && package.source != _selectedSource) {
          return false;
        }
        
        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _uninstallPackage(InstalledPackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Uninstall'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to uninstall ${package.name}?'),
            const SizedBox(height: 8),
            Text('Type: ${package.type.displayName}'),
            if (package.isSystemPackage) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'This is a system package!',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'This will remove the package but keep configuration files.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _performUninstall(package, false);
    }
  }

  Future<void> _purgePackage(InstalledPackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to purge ${package.name}?'),
            const SizedBox(height: 8),
            Text('Type: ${package.type.displayName}'),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Text(
                  'This will remove ALL files!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'This will completely remove the package and all configuration files.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Purge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _performUninstall(package, true);
    }
  }

  Future<void> _performUninstall(InstalledPackage package, bool purge) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(purge ? 'Purging...' : 'Uninstalling...'),
          ],
        ),
        content: Text('${purge ? 'Purging' : 'Uninstalling'} ${package.name}...'),
      ),
    );

    try {
      final result = purge 
          ? await _packageManager.purgePackage(package.name, source: package.source)
          : await _packageManager.uninstallPackage(package.name, source: package.source);
      
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        
        if (result.success) {
          _showSuccessDialog('Package ${purge ? 'purged' : 'uninstalled'} successfully');
          _loadPackages();
        } else {
          _showErrorDialog('${purge ? 'Purge' : 'Uninstall'} failed: ${result.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        _showErrorDialog('Error: $e');
      }
    }
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
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
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Installed Packages',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage and uninstall your installed packages',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apps_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredPackages.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search installed packages...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _filterPackages();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterPackages();
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Filters
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Show System Packages'),
                          selected: _showSystemApps,
                          onSelected: (value) {
                            setState(() {
                              _showSystemApps = value;
                              _filterPackages();
                            });
                          },
                          avatar: Icon(
                            Icons.security_rounded,
                            size: 16,
                            color: _showSystemApps 
                                ? Theme.of(context).colorScheme.onSecondaryContainer
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSource,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Sources')),
                                DropdownMenuItem(value: 'apt', child: Text('APT')),
                                DropdownMenuItem(value: 'snap', child: Text('Snap')),
                                DropdownMenuItem(value: 'flatpak', child: Text('Flatpak')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSource = value ?? 'all';
                                  _filterPackages();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadPackages,
                    tooltip: 'Refresh package list',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Package list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading installed packages...'),
                    ],
                  ),
                )
              : _filteredPackages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _filteredPackages.length,
                      itemBuilder: (context, index) {
                        final package = _filteredPackages[index];
                        return _buildPackageCard(package);
                      },
                    ),
        ),
      ],
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inbox_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ? 'No Packages Found' : 'No Packages Installed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No packages match your search criteria\nTry adjusting your filters'
                : 'You haven\'t installed any packages yet\nUse the Discover tab to find and install packages',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(InstalledPackage package) {
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
                    color: _getPackageTypeColor(package).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    package.type.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              package.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (package.isSystemPackage)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.security_rounded, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'SYSTEM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPackageTypeColor(package).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getPackageTypeColor(package).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              package.type.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getPackageTypeColor(package),
                              ),
                            ),
                          ),
                          if (package.version.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              'v${package.version}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Text(
                            package.source.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'uninstall') {
                      _uninstallPackage(package);
                    } else if (value == 'purge') {
                      _purgePackage(package);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'uninstall',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Uninstall'),
                        ],
                      ),
                    ),
                    if (!package.isSystemPackage)
                      const PopupMenuItem(
                        value: 'purge',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever_rounded, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Purge'),
                          ],
                        ),
                      ),
                  ],
                  icon: const Icon(Icons.more_vert_rounded),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPackageTypeColor(InstalledPackage package) {
    switch (package.source.toLowerCase()) {
      case 'apt':
        return Colors.orange;
      case 'snap':
        return Colors.green;
      case 'flatpak':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
