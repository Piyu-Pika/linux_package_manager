import 'package:shared_preferences/shared_preferences.dart';
import '../models/security_provider.dart';

class ApiConfig {
  // SharedPreferences keys
  static const String _selectedProviderKey = 'selected_security_provider';
  static const String _virusTotalApiKeyKey = 'virustotal_api_key';
  static const String _hybridAnalysisApiKeyKey = 'hybrid_analysis_api_key';
  static const String _metaDefenderApiKeyKey = 'metadefender_api_key';
  static const String _enableVirusScanningKey = 'enable_virus_scanning';
  static const String _isPremiumAccountKey = 'is_premium_account';

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration scanTimeout =
      Duration(minutes: 15); // Increased for behavioral analysis
  static const Duration pollInterval = Duration(seconds: 20);

  // Get/Set selected security provider
  static Future<SecurityProvider> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_selectedProviderKey) ?? 0;
    return SecurityProvider.values[index];
  }

  static Future<void> setSelectedProvider(SecurityProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedProviderKey, provider.index);
  }

  // Get API key for specific provider
  static Future<String> getApiKey(SecurityProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    switch (provider) {
      case SecurityProvider.virusTotal:
        return prefs.getString(_virusTotalApiKeyKey) ?? '';
      case SecurityProvider.hybridAnalysis:
        return prefs.getString(_hybridAnalysisApiKeyKey) ?? '';
      case SecurityProvider.metaDefender:
        return prefs.getString(_metaDefenderApiKeyKey) ?? '';
    }
  }

  // Set API key for specific provider
  static Future<void> setApiKey(
      SecurityProvider provider, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    switch (provider) {
      case SecurityProvider.virusTotal:
        await prefs.setString(_virusTotalApiKeyKey, apiKey.trim());
        break;
      case SecurityProvider.hybridAnalysis:
        await prefs.setString(_hybridAnalysisApiKeyKey, apiKey.trim());
        break;
      case SecurityProvider.metaDefender:
        await prefs.setString(_metaDefenderApiKeyKey, apiKey.trim());
        break;
    }
  }

  // Legacy methods for backward compatibility
  static Future<String> getVirusTotalApiKey() async {
    return getApiKey(SecurityProvider.virusTotal);
  }

  static Future<void> setVirusTotalApiKey(String apiKey) async {
    await setApiKey(SecurityProvider.virusTotal, apiKey);
  }

  // Check if virus scanning is enabled
  static Future<bool> isVirusScanningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableVirusScanningKey) ?? true;
  }

  // Set virus scanning enabled state
  static Future<void> setVirusScanningEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableVirusScanningKey, enabled);
  }

  // Check if current provider API key is configured
  static Future<bool> isApiKeyConfigured() async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    return apiKey.isNotEmpty && provider.validateApiKeyFormat(apiKey);
  }

  // Check if specific provider API key is configured
  static Future<bool> isProviderConfigured(SecurityProvider provider) async {
    final apiKey = await getApiKey(provider);
    return apiKey.isNotEmpty && provider.validateApiKeyFormat(apiKey);
  }

  // Validate API key format for current provider
  static Future<bool> isValidApiKeyFormat(String apiKey) async {
    final provider = await getSelectedProvider();
    return provider.validateApiKeyFormat(apiKey);
  }

  // Legacy method for backward compatibility
  static bool isValidApiKeyFormatSync(String apiKey) {
    // Default to VirusTotal format for legacy compatibility
    return SecurityProvider.virusTotal.validateApiKeyFormat(apiKey);
  }

  // Get premium account status
  static Future<bool> isPremiumAccount(SecurityProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_isPremiumAccountKey}_${provider.name}') ?? false;
  }

  // Set premium account status
  static Future<void> setPremiumAccount(
      SecurityProvider provider, bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_isPremiumAccountKey}_${provider.name}', isPremium);
  }

  // Get max file size for current provider
  static Future<int> getMaxFileSize() async {
    final provider = await getSelectedProvider();
    final isPremium = await isPremiumAccount(provider);
    return isPremium ? provider.maxFileSizePaid : provider.maxFileSizeFree;
  }

  // Get max file size for specific provider
  static Future<int> getMaxFileSizeForProvider(
      SecurityProvider provider) async {
    final isPremium = await isPremiumAccount(provider);
    return isPremium ? provider.maxFileSizePaid : provider.maxFileSizeFree;
  }

  // Clear all API settings
  static Future<void> clearApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_virusTotalApiKeyKey);
    await prefs.remove(_hybridAnalysisApiKeyKey);
    await prefs.remove(_metaDefenderApiKeyKey);
    await prefs.remove(_enableVirusScanningKey);
    await prefs.remove(_selectedProviderKey);
    // Clear premium status for all providers
    for (final provider in SecurityProvider.values) {
      await prefs.remove('${_isPremiumAccountKey}_${provider.name}');
    }
  }
}
