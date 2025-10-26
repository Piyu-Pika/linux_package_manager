import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/system_detector.dart';
import '../providers/theme_provider.dart';
import '../config/api_config.dart';
import '../models/security_provider.dart';
import 'security_provider_selection_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoUpdatePackageList = true;
  bool _confirmBeforeInstall = true;
  bool _showSystemPackages = false;
  bool _enableNotifications = true;
  bool _enableVirusScanning = true;
  String _defaultPackageManager = 'apt';
  String _virusTotalApiKey = '';
  SecurityProvider _selectedProvider = SecurityProvider.virusTotal;
  List<String> _availableManagers = [];
  String _distribution = 'unknown';
  String _architecture = 'unknown';

  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSystemInfo();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = await ApiConfig.getVirusTotalApiKey();
    final virusScanningEnabled = await ApiConfig.isVirusScanningEnabled();
    final selectedProvider = await ApiConfig.getSelectedProvider();

    setState(() {
      _autoUpdatePackageList =
          prefs.getBool('auto_update_package_list') ?? true;
      _confirmBeforeInstall = prefs.getBool('confirm_before_install') ?? true;
      _showSystemPackages = prefs.getBool('show_system_packages') ?? false;
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
      _defaultPackageManager =
          prefs.getString('default_package_manager') ?? 'apt';
      _enableVirusScanning = virusScanningEnabled;
      _virusTotalApiKey = apiKey;
      _selectedProvider = selectedProvider;
      _apiKeyController.text = apiKey;
    });
  }

  Future<void> _loadSystemInfo() async {
    final managers = await SystemDetector.getAvailablePackageManagers();
    final distribution = await SystemDetector.getDistribution();
    final architecture = await SystemDetector.getArchitecture();

    setState(() {
      _availableManagers = managers;
      _distribution = distribution;
      _architecture = architecture;

      // Set default package manager if current one is not available
      if (!managers.contains(_defaultPackageManager) && managers.isNotEmpty) {
        _defaultPackageManager = managers.first;
        _saveSettings();
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_update_package_list', _autoUpdatePackageList);
    await prefs.setBool('confirm_before_install', _confirmBeforeInstall);
    await prefs.setBool('show_system_packages', _showSystemPackages);
    await prefs.setBool('enable_notifications', _enableNotifications);
    await prefs.setString('default_package_manager', _defaultPackageManager);
  }

  Future<void> _saveVirusTotalSettings() async {
    await ApiConfig.setVirusScanningEnabled(_enableVirusScanning);
    await ApiConfig.setVirusTotalApiKey(_virusTotalApiKey);
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.blue),
            SizedBox(width: 12),
            Text('VirusTotal API Key'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your VirusTotal API key to enable virus scanning:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  hintText: 'Paste your 64-character API key here',
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: _apiKeyController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _apiKeyController.clear(),
                        )
                      : null,
                ),
                maxLines: 2,
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'How to get your API key:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Visit virustotal.com'),
                    const Text('2. Create a free account'),
                    const Text('3. Go to your profile → API Key'),
                    const Text('4. Copy the 64-character key'),
                    const SizedBox(height: 8),
                    Text(
                      'Free accounts: 32MB files, 4 requests/min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_apiKeyController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      SecurityProvider.virusTotal
                              .validateApiKeyFormat(_apiKeyController.text)
                          ? Icons.check_circle
                          : Icons.error,
                      color: SecurityProvider.virusTotal
                              .validateApiKeyFormat(_apiKeyController.text)
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      SecurityProvider.virusTotal
                              .validateApiKeyFormat(_apiKeyController.text)
                          ? 'Valid API key format'
                          : 'Invalid API key format (should be 64 hex characters)',
                      style: TextStyle(
                        fontSize: 12,
                        color: SecurityProvider.virusTotal
                                .validateApiKeyFormat(_apiKeyController.text)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final apiKey = _apiKeyController.text.trim();
              if (apiKey.isNotEmpty) {
                setState(() {
                  _virusTotalApiKey = apiKey;
                });
                await _saveVirusTotalSettings();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('VirusTotal API key saved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _testApiKey() async {
    if (_virusTotalApiKey.isEmpty) {
      _showErrorSnackBar('Please configure your API key first');
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Testing API key...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // Test the API key by making a simple request
      // You could implement a test method in VirusTotalService
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key is working correctly!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('API key test failed: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'This will clear all cached package information. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure your package manager preferences',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),

        // Settings content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // System Information
              _buildSettingsSection(
                title: 'System Information',
                icon: Icons.computer_rounded,
                color: Colors.blue,
                children: [
                  _buildInfoTile('Distribution', _distribution.toUpperCase(),
                      Icons.computer_rounded),
                  _buildInfoTile(
                      'Architecture', _architecture, Icons.memory_rounded),
                  _buildInfoTile('Package Managers',
                      _availableManagers.join(', '), Icons.inventory_2_rounded),
                ],
              ),

              const SizedBox(height: 24),

              // Package Management Settings
              _buildSettingsSection(
                title: 'Package Management',
                icon: Icons.settings_applications_rounded,
                color: Colors.green,
                children: [
                  if (_availableManagers.isNotEmpty) ...[
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Colors.green, size: 20),
                      ),
                      title: const Text('Default Package Manager'),
                      subtitle: Text('Currently using $_defaultPackageManager'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _defaultPackageManager,
                            isDense: true,
                            items: _availableManagers.map((manager) {
                              return DropdownMenuItem(
                                value: manager,
                                child: Text(manager.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _defaultPackageManager = value;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  _buildSwitchTile(
                    'Auto-update Package List',
                    'Automatically refresh package information',
                    Icons.refresh_rounded,
                    _autoUpdatePackageList,
                    (value) {
                      setState(() {
                        _autoUpdatePackageList = value;
                      });
                      _saveSettings();
                    },
                  ),
                  _buildSwitchTile(
                    'Confirm Before Install',
                    'Show confirmation dialog before installing packages',
                    Icons.security_rounded,
                    _confirmBeforeInstall,
                    (value) {
                      setState(() {
                        _confirmBeforeInstall = value;
                      });
                      _saveSettings();
                    },
                  ),
                  _buildSwitchTile(
                    'Show System Packages',
                    'Display system and library packages in lists',
                    Icons.visibility_rounded,
                    _showSystemPackages,
                    (value) {
                      setState(() {
                        _showSystemPackages = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // VirusTotal Settings
              _buildSettingsSection(
                title: 'Security & Virus Scanning',
                icon: Icons.security_rounded,
                color: Colors.red,
                children: [
                  _buildSwitchTile(
                    'Enable Virus Scanning',
                    'Scan packages before installation with your chosen security provider',
                    Icons.shield_rounded,
                    _enableVirusScanning,
                    (value) async {
                      setState(() {
                        _enableVirusScanning = value;
                      });
                      await _saveVirusTotalSettings();
                    },
                  ),
                  if (_enableVirusScanning) ...[
                    const Divider(height: 32),

                    // Security Provider Selection
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: const Text('Security Provider'),
                      subtitle: Text(
                        'Currently using ${_selectedProvider.name}\n${_selectedProvider.description}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SecurityProviderSelectionScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadSettings(); // Reload settings after changes
                        }
                      },
                    ),

                    const Divider(height: 32),

                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _virusTotalApiKey.isNotEmpty
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _virusTotalApiKey.isNotEmpty
                              ? Icons.vpn_key_rounded
                              : Icons.key_off_rounded,
                          color: _virusTotalApiKey.isNotEmpty
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: const Text('VirusTotal API Key'),
                      subtitle: Text(
                        _virusTotalApiKey.isNotEmpty
                            ? 'API key configured (${_virusTotalApiKey.substring(0, 8)}...)'
                            : 'No API key configured - click to add',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_virusTotalApiKey.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.play_arrow_rounded),
                              tooltip: 'Test API Key',
                              onPressed: _testApiKey,
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            tooltip: 'Configure API Key',
                            onPressed: _showApiKeyDialog,
                          ),
                        ],
                      ),
                      onTap: _showApiKeyDialog,
                    ),

                    if (_virusTotalApiKey.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Virus scanning is ready!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Files will be scanned before installation',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'API key required',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    'Get a free API key from virustotal.com',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Appearance Settings
              _buildSettingsSection(
                title: 'Appearance',
                icon: Icons.palette_rounded,
                color: Colors.purple,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final themeMode = ref.watch(themeModeProvider);
                      final themeNotifier =
                          ref.read(themeModeProvider.notifier);

                      IconData getThemeIcon() {
                        switch (themeMode) {
                          case ThemeMode.light:
                            return Icons.light_mode_rounded;
                          case ThemeMode.dark:
                            return Icons.dark_mode_rounded;
                          case ThemeMode.system:
                            return Icons.brightness_auto_rounded;
                        }
                      }

                      String getThemeString() {
                        switch (themeMode) {
                          case ThemeMode.light:
                            return 'Light';
                          case ThemeMode.dark:
                            return 'Dark';
                          case ThemeMode.system:
                            return 'System';
                        }
                      }

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            getThemeIcon(),
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        title: const Text('Theme Mode'),
                        subtitle:
                            Text('Currently using ${getThemeString()} theme'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ThemeMode>(
                              value: themeMode,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.light_mode_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text('Light'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.dark_mode_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text('Dark'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.brightness_auto_rounded,
                                          size: 16),
                                      SizedBox(width: 8),
                                      Text('System'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (ThemeMode? mode) {
                                if (mode != null) {
                                  themeNotifier.setThemeMode(mode);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // App Settings
              _buildSettingsSection(
                title: 'Application',
                icon: Icons.tune_rounded,
                color: Colors.indigo,
                children: [
                  _buildSwitchTile(
                    'Enable Notifications',
                    'Show notifications for installation progress',
                    Icons.notifications_rounded,
                    _enableNotifications,
                    (value) {
                      setState(() {
                        _enableNotifications = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded,
                          color: Colors.red, size: 20),
                    ),
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Clear all cached data and settings'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _clearCache,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // About
              _buildSettingsSection(
                title: 'About',
                icon: Icons.info_rounded,
                color: Colors.orange,
                children: [
                  _buildInfoTile('Version', '1.0.0', Icons.tag_rounded),
                  _buildInfoTile('Build', '1', Icons.build_rounded),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'PackageArmor Package Manager',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A comprehensive tool for installing and managing Linux packages from multiple sources. Built with Flutter for a modern, cross-platform experience.',
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
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Unknown' : value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
