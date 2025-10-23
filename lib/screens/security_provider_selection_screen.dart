import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/security_provider.dart';
import '../config/api_config.dart';

class SecurityProviderSelectionScreen extends ConsumerStatefulWidget {
  const SecurityProviderSelectionScreen({super.key});

  @override
  ConsumerState<SecurityProviderSelectionScreen> createState() => _SecurityProviderSelectionScreenState();
}

class _SecurityProviderSelectionScreenState extends ConsumerState<SecurityProviderSelectionScreen> {
  SecurityProvider? _selectedProvider;
  final Map<SecurityProvider, TextEditingController> _apiKeyControllers = {};
  final Map<SecurityProvider, bool> _isPremiumAccount = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    
    // Initialize controllers
    for (final provider in SecurityProvider.values) {
      _apiKeyControllers[provider] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _apiKeyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
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
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_selectedProvider != null) {
      await ApiConfig.setSelectedProvider(_selectedProvider!);
      
      // Save API keys and premium status
      for (final provider in SecurityProvider.values) {
        final apiKey = _apiKeyControllers[provider]!.text.trim();
        if (apiKey.isNotEmpty) {
          await ApiConfig.setApiKey(provider, apiKey);
        }
        await ApiConfig.setPremiumAccount(provider, _isPremiumAccount[provider] ?? false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security provider settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Provider'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info_outline, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Choose Your Security Provider',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select the security scanning service that best fits your needs. Each provider offers different strengths and capabilities.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Provider selection cards
            ...SecurityProvider.values.map((provider) => _buildProviderCard(provider)),
            
            const SizedBox(height: 24),
            
            // Comparison table
            _buildComparisonTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(SecurityProvider provider) {
    final isSelected = _selectedProvider == provider;
    final apiKey = _apiKeyControllers[provider]!.text;
    final isConfigured = apiKey.isNotEmpty && provider.validateApiKeyFormat(apiKey);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProvider = provider;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<SecurityProvider>(
                    value: provider,
                    groupValue: _selectedProvider,
                    onChanged: (value) {
                      setState(() {
                        _selectedProvider = value;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              provider.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isConfigured)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 12, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Configured',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Detailed description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.detailedDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.recommend_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Best for: ${provider.recommendedFor}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // API Key configuration
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apiKeyControllers[provider],
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'Enter your ${provider.name} API key',
                        prefixIcon: const Icon(Icons.vpn_key),
                        suffixIcon: apiKey.isNotEmpty
                            ? Icon(
                                provider.validateApiKeyFormat(apiKey)
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: provider.validateApiKeyFormat(apiKey)
                                    ? Colors.green
                                    : Colors.red,
                              )
                            : null,
                      ),
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () => _showApiKeyInstructions(provider),
                        tooltip: 'How to get API key',
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => _launchUrl(provider.website),
                        tooltip: 'Visit ${provider.name}',
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Premium account toggle
              Row(
                children: [
                  Checkbox(
                    value: _isPremiumAccount[provider] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _isPremiumAccount[provider] = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium Account',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Higher file size limits and additional features',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Feature')),
                  DataColumn(label: Text('VirusTotal')),
                  DataColumn(label: Text('Hybrid Analysis')),
                  DataColumn(label: Text('MetaDefender')),
                ],
                rows: [
                  _buildComparisonRow('Antivirus Engines', '70+', '1 (Behavioral)', '30+'),
                  _buildComparisonRow('Free File Size', '32MB', '100MB', '50MB'),
                  _buildComparisonRow('Paid File Size', '650MB', '500MB', '1GB'),
                  _buildComparisonRow('Analysis Type', 'Static', 'Dynamic/Behavioral', 'Static + DLP'),
                  _buildComparisonRow('Scan Speed', 'Fast (1-2 min)', 'Slow (5-15 min)', 'Medium (2-5 min)'),
                  _buildComparisonRow('Zero-day Detection', 'Good', 'Excellent', 'Good'),
                  _buildComparisonRow('Enterprise Features', 'Limited', 'Advanced', 'Comprehensive'),
                  _buildComparisonRow('Best For', 'General Use', 'Research/Analysis', 'Enterprise'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildComparisonRow(String feature, String vt, String ha, String md) {
    return DataRow(
      cells: [
        DataCell(Text(feature, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(vt)),
        DataCell(Text(ha)),
        DataCell(Text(md)),
      ],
    );
  }

  void _showApiKeyInstructions(SecurityProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${provider.name} API Key'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to get your ${provider.name} API key:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(provider.apiKeyInstructions),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Free accounts have limitations. Consider upgrading for better performance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(provider.website);
            },
            child: Text('Visit ${provider.name}'),
          ),
        ],
      ),
    );
  }
}