/// Helper class to categorize apps into different categories
class AppCategoryHelper {
  // Social Media Apps
  static const List<String> socialMediaApps = [
    'facebook',
    'instagram',
    'twitter',
    'tiktok',
    'snapchat',
    'linkedin',
    'pinterest',
    'reddit',
    'whatsapp',
    'telegram',
    'discord',
    'messenger',
  ];

  // Entertainment Apps
  static const List<String> entertainmentApps = [
    'youtube',
    'netflix',
    'spotify',
    'prime video',
    'disney',
    'twitch',
    'games',
    'gaming',
    'music',
    'video',
    'streaming',
  ];

  // Communication Apps
  static const List<String> communicationApps = [
    'whatsapp',
    'messenger',
    'telegram',
    'viber',
    'skype',
    'zoom',
    'teams',
    'call',
    'message',
    'sms',
    'phone',
  ];

  // Education Apps
  static const List<String> educationApps = [
    'khan academy',
    'duolingo',
    'coursera',
    'udemy',
    'edx',
    'education',
    'learn',
    'study',
    'school',
    'college',
    'university',
  ];

  // Productivity Apps
  static const List<String> productivityApps = [
    'google',
    'chrome',
    'safari',
    'firefox',
    'edge',
    'microsoft',
    'office',
    'word',
    'excel',
    'powerpoint',
    'notes',
    'calendar',
    'reminder',
  ];

  /// Get category for an app based on its name or package name
  static AppCategory getCategory(String appName, String packageName) {
    final lowerAppName = appName.toLowerCase();
    final lowerPackageName = packageName.toLowerCase();

    // Check Social Media
    if (socialMediaApps.any((keyword) => 
        lowerAppName.contains(keyword) || lowerPackageName.contains(keyword))) {
      return AppCategory.socialMedia;
    }

    // Check Entertainment
    if (entertainmentApps.any((keyword) => 
        lowerAppName.contains(keyword) || lowerPackageName.contains(keyword))) {
      return AppCategory.entertainment;
    }

    // Check Communication
    if (communicationApps.any((keyword) => 
        lowerAppName.contains(keyword) || lowerPackageName.contains(keyword))) {
      return AppCategory.communication;
    }

    // Check Education
    if (educationApps.any((keyword) => 
        lowerAppName.contains(keyword) || lowerPackageName.contains(keyword))) {
      return AppCategory.education;
    }

    // Check Productivity
    if (productivityApps.any((keyword) => 
        lowerAppName.contains(keyword) || lowerPackageName.contains(keyword))) {
      return AppCategory.productivity;
    }

    // Default to Others
    return AppCategory.others;
  }

  /// Get color for category
  static int getCategoryColor(AppCategory category) {
    switch (category) {
      case AppCategory.socialMedia:
        return 0xFFFF6B6B; // Red/Orange
      case AppCategory.entertainment:
        return 0xFFFFD93D; // Yellow
      case AppCategory.communication:
        return 0xFFFF9500; // Orange
      case AppCategory.education:
        return 0xFF4ECDC4; // Teal/Cyan
      case AppCategory.productivity:
        return 0xFF6C5CE7; // Purple
      case AppCategory.others:
        return 0xFF95A5A6; // Grey
    }
  }

  /// Get display name for category
  static String getCategoryName(AppCategory category) {
    switch (category) {
      case AppCategory.socialMedia:
        return 'Social Media';
      case AppCategory.entertainment:
        return 'Entertainment';
      case AppCategory.communication:
        return 'Communication';
      case AppCategory.education:
        return 'Education';
      case AppCategory.productivity:
        return 'Productivity';
      case AppCategory.others:
        return 'Others';
    }
  }
}

enum AppCategory {
  socialMedia,
  entertainment,
  communication,
  education,
  productivity,
  others,
}

