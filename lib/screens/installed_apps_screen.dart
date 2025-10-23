import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/package_provider.dart';
import '../models/installed_package.dart';

class InstalledAppsScreen extends ConsumerStatefulWidget {
  const InstalledAppsScreen({super.key});

  @override
  ConsumerState<InstalledAppsScreen> createState() =>
      _InstalledAppsScreenState();
}

class _InstalledAppsScreenState extends ConsumerState<InstalledAppsScreen> {
  List<InstalledPackage> _filteredPackages = [];
  String _searchQuery = '';
  bool _showSystemApps = false;
  String _selectedSource = 'all';
  List<String> _availableUpdates = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableUpdates();
  }

  Future<void> _loadAvailableUpdates() async {
    try {
      final updates = await ref
          .read(availableUpdatesProvider(source: _selectedSource).future);
      setState(() {
        _availableUpdates = updates;
      });
    } catch (e) {
      // Handle error silently for updates
    }
  }

  void _filterPackages(List<InstalledPackage> packages) {
    setState(() {
      _filteredPackages = packages.where((package) {
        final matchesSearch =
            package.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                package.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

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
        content:
            Text('${purge ? 'Purging' : 'Uninstalling'} ${package.name}...'),
      ),
    );

    try {
      final packageManager = ref.read(packageManagerProvider);
      final result = purge
          ? await packageManager.purgePackage(package.name,
              source: package.source)
          : await packageManager.uninstallPackage(package.name,
              source: package.source);

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        if (result.success) {
          _showSuccessDialog(
              'Package ${purge ? 'purged' : 'uninstalled'} successfully');
          ref.invalidate(installedPackagesProvider);
        } else {
          _showErrorDialog(
              '${purge ? 'Purge' : 'Uninstall'} failed: ${result.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> _updatePackage(InstalledPackage package) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Updating...'),
          ],
        ),
        content: Text('Updating ${package.name}...'),
      ),
    );

    try {
      final packageManager = ref.read(packageManagerProvider);
      final result = await packageManager.updatePackage(package.name,
          source: package.source);

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        if (result.success) {
          _showSuccessDialog('Package updated successfully');
          ref.invalidate(installedPackagesProvider);
          _loadAvailableUpdates();
        } else {
          _showErrorDialog('Update failed: ${result.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> _updateAllPackages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update All Packages'),
        content: const Text(
            'This will update all packages that have available updates. This may take some time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Updating All...'),
            ],
          ),
          content: Text('Updating all packages...'),
        ),
      );

      try {
        final packageManager = ref.read(packageManagerProvider);
        final result =
            await packageManager.updateAllPackages(source: _selectedSource);

        if (mounted) {
          Navigator.pop(context); // Close progress dialog

          if (result.success) {
            _showSuccessDialog('All packages updated successfully');
            ref.invalidate(installedPackagesProvider);
            _loadAvailableUpdates();
          } else {
            _showErrorDialog('Update failed: ${result.error}');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close progress dialog
          _showErrorDialog('Error: $e');
        }
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
    final packagesAsync = ref.watch(installedPackagesProvider);

    return Column(
      children: [
        // Header section with search and filters
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage, update, and uninstall your installed packages',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredPackages.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
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
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
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
                            });
                          },
                          avatar: Icon(
                            Icons.security_rounded,
                            size: 16,
                            color: _showSystemApps
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSource,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'all', child: Text('All Sources')),
                                DropdownMenuItem(
                                    value: 'apt', child: Text('APT')),
                                DropdownMenuItem(
                                    value: 'snap', child: Text('Snap')),
                                DropdownMenuItem(
                                    value: 'flatpak', child: Text('Flatpak')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedSource = value ?? 'all';
                                });
                                _loadAvailableUpdates();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_availableUpdates.isNotEmpty)
                        FilledButton.icon(
                          onPressed: _updateAllPackages,
                          icon: const Icon(Icons.system_update_rounded),
                          label:
                              Text('Update All (${_availableUpdates.length})'),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () {
                          ref.invalidate(installedPackagesProvider);
                          _loadAvailableUpdates();
                        },
                        tooltip: 'Refresh package list',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Package list
        Expanded(
          child: packagesAsync.when(
            data: (packages) {
              // Filter packages when data changes
              if (_filteredPackages.isEmpty ||
                  _filteredPackages.length != packages.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _filterPackages(packages);
                });
              }

              return _filteredPackages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _filteredPackages.length,
                      itemBuilder: (context, index) {
                        final package = _filteredPackages[index];
                        return _buildPackageCard(package);
                      },
                    );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading installed packages...'),
                ],
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading packages: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(installedPackagesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
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
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.inbox_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No Packages Found'
                : 'No Packages Installed',
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
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
                    color: _getPackageTypeColor(package).withValues(alpha: 0.1),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (package.isSystemPackage)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.security_rounded,
                                      size: 12, color: Colors.orange),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPackageTypeColor(package)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getPackageTypeColor(package)
                                    .withValues(alpha: 0.3),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Text(
                            package.source.toUpperCase(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_availableUpdates.contains(package.name))
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilledButton.icon(
                          onPressed: () => _updatePackage(package),
                          icon:
                              const Icon(Icons.system_update_rounded, size: 16),
                          label: const Text('Update'),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'update') {
                          _updatePackage(package);
                        } else if (value == 'uninstall') {
                          _uninstallPackage(package);
                        } else if (value == 'purge') {
                          _purgePackage(package);
                        }
                      },
                      itemBuilder: (context) => [
                        if (_availableUpdates.contains(package.name))
                          const PopupMenuItem(
                            value: 'update',
                            child: Row(
                              children: [
                                Icon(Icons.system_update_rounded,
                                    color: Colors.blue),
                                SizedBox(width: 12),
                                Text('Update'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'uninstall',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: Colors.orange),
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
                                Icon(Icons.delete_forever_rounded,
                                    color: Colors.red),
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
              ],
            ),
            if (package.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                package.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
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
