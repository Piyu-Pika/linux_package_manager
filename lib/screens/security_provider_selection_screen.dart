import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/security_provider.dart';
import '../config/api_config.dart';

class SecurityProviderSelectionScreen extends ConsumerStatefulWidget {
  const SecurityProviderSelectionScreen({super.key});

  @override
  ConsumerState<SecurityProviderSelectionScreen> createState() =>
      _SecurityProviderSelectionScreenState();
}

class _SecurityProviderSelectionScreenState
    extends ConsumerState<SecurityProviderSelectionScreen>
    with SingleTickerProviderStateMixin {
  SecurityProvider? _selectedProvider;
  final Map<SecurityProvider, TextEditingController> _apiKeyControllers = {};
  final Map<SecurityProvider, bool> _isPremiumAccount = {};
  final Map<SecurityProvider, bool> _isExpanded = {};
  final Map<SecurityProvider, bool> _showApiKey = {};
  late AnimationController _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCurrentSettings();

    // Initialize controllers
    for (final provider in SecurityProvider.values) {
      _apiKeyControllers[provider] = TextEditingController();
      _isExpanded[provider] = false;
      _showApiKey[provider] = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _apiKeyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);

    final currentProvider = await ApiConfig.getSelectedProvider();

    setState(() {
      _selectedProvider = currentProvider;
    });

    // Load API keys and premium status for all providers
    for (final provider in SecurityProvider.values) {
      final apiKey = await ApiConfig.getApiKey(provider);
      final isPremium = await ApiConfig.isPremiumAccount(provider);

      setState(() {
        _apiKeyControllers[provider]!.text = apiKey;
        _isPremiumAccount[provider] = isPremium;
        if (_selectedProvider == provider) {
          _isExpanded[provider] = true;
        }
      });
    }

    setState(() => _isLoading = false);
    _animationController.forward();
  }

  Future<void> _saveSettings() async {
    if (_selectedProvider != null) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving settings...'),
                ],
              ),
            ),
          ),
        ),
      );

      await ApiConfig.setSelectedProvider(_selectedProvider!);

      // Save API keys and premium status
      for (final provider in SecurityProvider.values) {
        final apiKey = _apiKeyControllers[provider]!.text.trim();
        if (apiKey.isNotEmpty) {
          await ApiConfig.setApiKey(provider, apiKey);
        }
        await ApiConfig.setPremiumAccount(
            provider, _isPremiumAccount[provider] ?? false);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Security provider settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a security provider'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getProviderColor(SecurityProvider provider) {
    switch (provider) {
      case SecurityProvider.virusTotal:
        return Colors.blue;
      case SecurityProvider.hybridAnalysis:
        return Colors.purple;
      case SecurityProvider.metaDefender:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getProviderIcon(SecurityProvider provider) {
    switch (provider) {
      case SecurityProvider.virusTotal:
        return Icons.verified_user;
      case SecurityProvider.hybridAnalysis:
        return Icons.science;
      case SecurityProvider.metaDefender:
        return Icons.shield;
      default:
        return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Provider',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading security providers...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _animationController,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero section
                    _buildHeroSection(theme),

                    const SizedBox(height: 24),

                    // Quick stats
                    _buildQuickStats(theme),

                    const SizedBox(height: 24),

                    // Provider selection cards
                    ...SecurityProvider.values
                        .map((provider) => _buildProviderCard(provider, theme)),

                    const SizedBox(height: 24),

                    // Comparison table
                    _buildComparisonTable(theme),

                    const SizedBox(height: 24),

                    // Help section
                    _buildHelpSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Security Provider',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Protect your files with industry-leading security',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Each provider offers unique strengths. Compare features below to find the best fit.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final configuredCount = _apiKeyControllers.entries
        .where((e) =>
            e.value.text.isNotEmpty && e.key.validateApiKeyFormat(e.value.text))
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.check_circle,
            configuredCount.toString(),
            'Configured',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.stars,
            _isPremiumAccount.values.where((v) => v).length.toString(),
            'Premium',
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.apps,
            SecurityProvider.values.length.toString(),
            'Available',
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(SecurityProvider provider, ThemeData theme) {
    final isSelected = _selectedProvider == provider;
    final apiKey = _apiKeyControllers[provider]!.text;
    final isConfigured =
        apiKey.isNotEmpty && provider.validateApiKeyFormat(apiKey);
    final isExpanded = _isExpanded[provider] ?? false;
    final providerColor = _getProviderColor(provider);
    final providerIcon = _getProviderIcon(provider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 8 : 2,
      shadowColor: providerColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: providerColor, width: 2)
            : BorderSide.none,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    providerColor.withOpacity(0.05),
                    providerColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedProvider = provider;
                  _isExpanded[provider] = !isExpanded;
                });
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Provider icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: providerColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            providerIcon,
                            color: providerColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    provider.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isConfigured)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.green.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Ready',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_isPremiumAccount[provider] ?? false)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade400,
                                            Colors.amber.shade700,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.workspace_premium,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Premium',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<SecurityProvider>(
                          value: provider,
                          groupValue: _selectedProvider,
                          activeColor: providerColor,
                          onChanged: (value) {
                            setState(() {
                              _selectedProvider = value;
                              _isExpanded[provider] = true;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: providerColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: providerColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.detailedDescription,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: providerColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Best for: ${provider.recommendedFor}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: providerColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildApiKeyField(provider, theme, providerColor),
                    const SizedBox(height: 16),
                    _buildPremiumToggle(provider, theme, providerColor),
                    const SizedBox(height: 16),
                    _buildActionButtons(provider, theme, providerColor),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyField(
    SecurityProvider provider,
    ThemeData theme,
    Color providerColor,
  ) {
    final apiKey = _apiKeyControllers[provider]!.text;
    final showPassword = _showApiKey[provider] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: apiKey.isNotEmpty
              ? (provider.validateApiKeyFormat(apiKey)
                  ? Colors.green.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5))
              : theme.colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _apiKeyControllers[provider],
        decoration: InputDecoration(
          labelText: 'API Key',
          hintText: 'Enter your ${provider.name} API key',
          prefixIcon: Icon(Icons.vpn_key, color: providerColor),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (apiKey.isNotEmpty)
                Icon(
                  provider.validateApiKeyFormat(apiKey)
                      ? Icons.check_circle
                      : Icons.error,
                  color: provider.validateApiKeyFormat(apiKey)
                      ? Colors.green
                      : Colors.red,
                ),
              IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showApiKey[provider] = !showPassword;
                  });
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        obscureText: !showPassword,
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildPremiumToggle(
    SecurityProvider provider,
    ThemeData theme,
    Color providerColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Higher limits & advanced features',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPremiumAccount[provider] ?? false,
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() {
                _isPremiumAccount[provider] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    SecurityProvider provider,
    ThemeData theme,
    Color providerColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showApiKeyInstructions(provider),
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('How to Get Key'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _launchUrl(provider.website),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Visit Website'),
            style: FilledButton.styleFrom(
              backgroundColor: providerColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Feature Comparison',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      theme.colorScheme.primaryContainer.withOpacity(0.5),
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return theme.colorScheme.primaryContainer
                            .withOpacity(0.1);
                      }
                      return null;
                    }),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Feature',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.verified_user,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'VirusTotal',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.science, size: 16, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text(
                              'Hybrid Analysis',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Icon(Icons.shield, size: 16, color: Colors.teal),
                            const SizedBox(width: 4),
                            Text(
                              'MetaDefender',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    rows: [
                      _buildComparisonRow(
                          '🔍 Antivirus Engines', '70+', '1', '30+', theme),
                      _buildComparisonRow(
                          '📦 Free File Size', '32MB', '100MB', '50MB', theme),
                      _buildComparisonRow(
                          '💎 Paid File Size', '650MB', '500MB', '1GB', theme),
                      _buildComparisonRow('⚡ Analysis Type', 'Static',
                          'Dynamic', 'Static + DLP', theme),
                      _buildComparisonRow('⏱️ Scan Speed', 'Fast (1-2 min)',
                          'Slow (5-15 min)', 'Medium (2-5 min)', theme),
                      _buildComparisonRow('🎯 Zero-day Detection', 'Good',
                          'Excellent', 'Good', theme),
                      _buildComparisonRow('🏢 Enterprise Features', 'Limited',
                          'Advanced', 'Comprehensive', theme),
                      _buildComparisonRow('✨ Best For', 'General Use',
                          'Research', 'Enterprise', theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildComparisonRow(
    String feature,
    String vt,
    String ha,
    String md,
    ThemeData theme,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            feature,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(vt)),
        DataCell(Text(ha)),
        DataCell(Text(md)),
      ],
    );
  }

  Widget _buildHelpSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Need Help?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              theme,
              Icons.key,
              'API Key Issues',
              'Make sure you\'re copying the complete API key without spaces',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              theme,
              Icons.attach_money,
              'Free vs Premium',
              'Free accounts have lower limits. Upgrade for better performance',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              theme,
              Icons.security,
              'Security',
              'Your API keys are stored securely on your device',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyInstructions(SecurityProvider provider) {
    final providerColor = _getProviderColor(provider);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      providerColor.withOpacity(0.2),
                      providerColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: providerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getProviderIcon(provider),
                        color: providerColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'API Key Setup',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to get your API key:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        provider.apiKeyInstructions,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Free accounts have limitations. Consider upgrading for better performance and higher limits.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.blue.shade900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _launchUrl(provider.website);
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text('Visit ${provider.name}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: providerColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
