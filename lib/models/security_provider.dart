enum SecurityProvider {
  virusTotal,
  hybridAnalysis,
  metaDefender,
}

extension SecurityProviderExtension on SecurityProvider {
  String get name {
    switch (this) {
      case SecurityProvider.virusTotal:
        return 'VirusTotal';
      case SecurityProvider.hybridAnalysis:
        return 'Hybrid Analysis';
      case SecurityProvider.metaDefender:
        return 'MetaDefender';
    }
  }

  String get description {
    switch (this) {
      case SecurityProvider.virusTotal:
        return 'The most popular multi-engine scanner with 70+ antivirus engines. Best for general malware detection and community-driven threat intelligence.';
      case SecurityProvider.hybridAnalysis:
        return 'Advanced behavioral analysis and sandboxing. Excellent for detecting zero-day threats, advanced persistent threats (APTs), and sophisticated malware.';
      case SecurityProvider.metaDefender:
        return 'Enterprise-grade security with 30+ engines plus data sanitization. Ideal for business environments requiring comprehensive threat prevention.';
    }
  }

  String get detailedDescription {
    switch (this) {
      case SecurityProvider.virusTotal:
        return '''
**VirusTotal** - Community-Powered Multi-Engine Scanner

• **Engines**: 70+ antivirus engines and URL/domain scanners
• **Strengths**: 
  - Largest community database
  - Real-time threat intelligence
  - Comprehensive file analysis
  - Free tier available
• **Best For**: 
  - General users and developers
  - Quick malware detection
  - Community-driven threat research
• **Limitations**: 
  - 32MB file size limit (free)
  - Rate limiting on free accounts
  - Public submission (files are shared)
• **Free Tier**: 4 requests/minute, 32MB files
• **Paid Tier**: Higher limits, private scanning, API access''';

      case SecurityProvider.hybridAnalysis:
        return '''
**Hybrid Analysis** - Advanced Behavioral Analysis

• **Technology**: Dynamic malware analysis and sandboxing
• **Strengths**:
  - Behavioral analysis in isolated environments
  - Zero-day threat detection
  - Advanced evasion technique detection
  - Detailed execution reports
• **Best For**:
  - Security researchers and analysts
  - Enterprise security teams
  - Advanced threat hunting
  - Suspicious file investigation
• **Limitations**:
  - Slower analysis (5-15 minutes)
  - Smaller engine count than VirusTotal
  - More complex results interpretation
• **Free Tier**: Limited submissions per day
• **Paid Tier**: Priority analysis, bulk submissions''';

      case SecurityProvider.metaDefender:
        return '''
**MetaDefender** - Enterprise Security Platform

• **Technology**: Multi-scanning + data sanitization + threat intelligence
• **Strengths**:
  - Enterprise-grade security
  - Data Loss Prevention (DLP)
  - File sanitization and reconstruction
  - Vulnerability assessment
• **Best For**:
  - Enterprise environments
  - Regulated industries (finance, healthcare)
  - Organizations requiring data sanitization
  - Compliance-focused security
• **Limitations**:
  - More expensive than alternatives
  - Overkill for personal use
  - Complex feature set
• **Free Tier**: Basic scanning with limited features
• **Paid Tier**: Full enterprise features, SLA support''';
    }
  }

  String get recommendedFor {
    switch (this) {
      case SecurityProvider.virusTotal:
        return 'Home users, developers, general malware detection';
      case SecurityProvider.hybridAnalysis:
        return 'Security professionals, researchers, advanced threat analysis';
      case SecurityProvider.metaDefender:
        return 'Enterprises, regulated industries, compliance requirements';
    }
  }

  String get website {
    switch (this) {
      case SecurityProvider.virusTotal:
        return 'https://www.virustotal.com';
      case SecurityProvider.hybridAnalysis:
        return 'https://www.hybrid-analysis.com';
      case SecurityProvider.metaDefender:
        return 'https://metadefender.opswat.com';
    }
  }

  String get apiKeyInstructions {
    switch (this) {
      case SecurityProvider.virusTotal:
        return '''
1. Visit virustotal.com
2. Create a free account
3. Go to your profile → API Key
4. Copy the 64-character hexadecimal key''';

      case SecurityProvider.hybridAnalysis:
        return '''
1. Visit hybrid-analysis.com
2. Register for a free account
3. Go to Profile → API Key
4. Generate and copy your API key''';

      case SecurityProvider.metaDefender:
        return '''
1. Visit metadefender.opswat.com
2. Sign up for an account
3. Navigate to API → API Keys
4. Create and copy your API key''';
    }
  }

  int get maxFileSizeFree {
    switch (this) {
      case SecurityProvider.virusTotal:
        return 32 * 1024 * 1024; // 32MB
      case SecurityProvider.hybridAnalysis:
        return 100 * 1024 * 1024; // 100MB
      case SecurityProvider.metaDefender:
        return 50 * 1024 * 1024; // 50MB
    }
  }

  int get maxFileSizePaid {
    switch (this) {
      case SecurityProvider.virusTotal:
        return 650 * 1024 * 1024; // 650MB
      case SecurityProvider.hybridAnalysis:
        return 500 * 1024 * 1024; // 500MB
      case SecurityProvider.metaDefender:
        return 1024 * 1024 * 1024; // 1GB
    }
  }

  String get baseUrl {
    switch (this) {
      case SecurityProvider.virusTotal:
        return 'https://www.virustotal.com/vtapi/v2';
      case SecurityProvider.hybridAnalysis:
        return 'https://www.hybrid-analysis.com/api/v2';
      case SecurityProvider.metaDefender:
        return 'https://api.metadefender.com/v4';
    }
  }

  bool validateApiKeyFormat(String apiKey) {
    switch (this) {
      case SecurityProvider.virusTotal:
        // 64-character hexadecimal string
        return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(apiKey.trim());
      case SecurityProvider.hybridAnalysis:
        // Typically 40-character alphanumeric
        return RegExp(r'^[a-zA-Z0-9]{32,64}$').hasMatch(apiKey.trim());
      case SecurityProvider.metaDefender:
        // Variable length alphanumeric with possible special characters
        return apiKey.trim().length >= 20 && apiKey.trim().length <= 100;
    }
  }
}
