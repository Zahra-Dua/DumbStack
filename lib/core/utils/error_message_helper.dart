/// Utility class for consistent error messages across the app
class ErrorMessageHelper {
  // Network error messages (consistent across all use cases)
  static const String networkErrorLogin = 
      'Login failed due to a network error. Please try again.';
  
  static const String networkErrorSignup = 
      'Registration failed due to a network error. Please try again.';
  
  static const String networkErrorProfileCreation = 
      'Profile creation failed due to a network error. Please try again.';
  
  static const String networkErrorProfileUpdate = 
      'Profile update failed due to a network error. Please try again.';
  
  static const String networkErrorProfileDeletion = 
      'Deletion failed due to a network error. Please try again.';
  
  static const String networkErrorLinking = 
      'Linking failed due to a network error. Please try again.';
  
  static const String networkErrorRetrieval = 
      'Unable to retrieve profile data due to a network error. Please try again.';
  
  static const String networkErrorLogout = 
      'Logout failed due to a network error. Please try again.';
  
  static const String networkErrorQRGeneration = 
      'QR code generation failed due to a network error. Please try again.';
  
  // Generic network error
  static const String networkErrorGeneric = 
      'Network connection failed. Please check your internet connection and try again.';
  
  // Invalid credentials
  static const String invalidCredentials = 
      'Invalid email/phone number or password. Please try again.';
  
  // Linking code errors
  static const String invalidLinkingCode = 
      'Invalid or expired linking code. Please request a new code.';
  
  static const String expiredLinkingCode = 
      'This linking code has expired. Please request a new code.';
  
  // Helper method to check if error is network-related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('socketexception') ||
           errorString.contains('handshakeexception') ||
           errorString.contains('interrupted') ||
           errorString.contains('unreachable') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('failed host lookup');
  }
  
  // Get appropriate network error message based on context
  static String getNetworkErrorMessage(String context) {
    switch (context.toLowerCase()) {
      case 'login':
        return networkErrorLogin;
      case 'signup':
      case 'registration':
        return networkErrorSignup;
      case 'profile_creation':
      case 'create_profile':
        return networkErrorProfileCreation;
      case 'profile_update':
      case 'update_profile':
        return networkErrorProfileUpdate;
      case 'profile_deletion':
      case 'delete_profile':
        return networkErrorProfileDeletion;
      case 'linking':
      case 'link':
        return networkErrorLinking;
      case 'retrieval':
      case 'retrieve':
        return networkErrorRetrieval;
      case 'logout':
        return networkErrorLogout;
      case 'qr_generation':
      case 'qr':
        return networkErrorQRGeneration;
      default:
        return networkErrorGeneric;
    }
  }
}

