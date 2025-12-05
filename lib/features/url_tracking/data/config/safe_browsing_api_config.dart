/// Safe Browsing API Configuration
/// 
/// ⚠️ IMPORTANT: Yahan apni Google Safe Browsing API key add karein
/// 
/// Steps:
/// 1. Google Cloud Console (https://console.cloud.google.com/apis/credentials) se API key generate karein
/// 2. Neeche wali line mein API key paste karein
/// 3. File save karein
/// 
/// Example:
/// static const String apiKey = 'AIzaSyA_31x3ddRKwdNOWnweWzZjMFvBgHf47H8';
class SafeBrowsingApiConfig {
  // ⬇️ YAHAN APNI SAFE BROWSING API KEY ADD KAREIN ⬇️
  static const String apiKey = 'AIzaSyA_31x3ddRKwdNOWnweWzZjMFvBgHf47H8';
  
  /// Check if API key is configured
  static bool get isApiKeyConfigured {
    return apiKey.isNotEmpty && 
           apiKey != 'YOUR_SAFE_BROWSING_API_KEY_HERE' &&
           apiKey.length > 20;
  }
}

