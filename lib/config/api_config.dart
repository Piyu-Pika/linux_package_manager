import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // SharedPreferences keys
  static const String _virusTotalApiKeyKey = 'virustotal_api_key';
  static const String _enableVirusScanningKey = 'enable_virus_scanning';
  
  // API endpoints
  static const String virusTotalBaseUrl = 'https://www.virustotal.com/vtapi/v2';
  
  // File size limits
  static const int maxFileSizeForScanning = 32 * 1024 * 1024; // 32MB for free API
  static const int maxFileSizeForPremium = 650 * 1024 * 1024; // 650MB for premium API
  
  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration scanTimeout = Duration(minutes: 10);
  static const Duration pollInterval = Duration(seconds: 15);
  
  // Get VirusTotal API key from SharedPreferences
  static Future<String> getVirusTotalApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_virusTotalApiKeyKey) ?? '';
  }
  
  // Set VirusTotal API key in SharedPreferences
  static Future<void> setVirusTotalApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_virusTotalApiKeyKey, apiKey.trim());
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
  
  // Check if API key is configured
  static Future<bool> isApiKeyConfigured() async {
    final apiKey = await getVirusTotalApiKey();
    return apiKey.isNotEmpty && apiKey.length >= 32; // VirusTotal API keys are typically 64 characters
  }
  
  // Validate API key format
  static bool isValidApiKeyFormat(String apiKey) {
    // VirusTotal API keys are 64-character hexadecimal strings
    final regex = RegExp(r'^[a-fA-F0-9]{64}$');
    return regex.hasMatch(apiKey.trim());
  }
  
  // Clear all API settings
  static Future<void> clearApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_virusTotalApiKeyKey);
    await prefs.remove(_enableVirusScanningKey);
  }
}