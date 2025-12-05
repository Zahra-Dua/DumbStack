/// Alert types for different notification scenarios
enum AlertType {
  /// Suspicious SMS/Message detected
  suspiciousMessage,
  
  /// Suspicious call detected
  suspiciousCall,
  
  /// Geofencing alert (entry/exit)
  geofencing,
  
  /// SOS emergency alert
  sos,
  
  /// Screen time limit reached
  screenTimeLimit,
  
  /// App/Website blocked
  appWebsiteBlocked,
  
  /// Emotional distress detected
  emotionalDistress,
  
  /// Toxic behavior pattern
  toxicBehaviorPattern,
  
  /// Suspicious contacts pattern
  suspiciousContactsPattern,
  
  /// Predictive threat alert
  predictiveThreat,
  
  /// General alert
  general,
}

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.suspiciousMessage:
        return 'Suspicious Message';
      case AlertType.suspiciousCall:
        return 'Suspicious Call';
      case AlertType.geofencing:
        return 'Geofencing Alert';
      case AlertType.sos:
        return 'SOS Emergency';
      case AlertType.screenTimeLimit:
        return 'Screen Time Limit';
      case AlertType.appWebsiteBlocked:
        return 'App/Website Blocked';
      case AlertType.emotionalDistress:
        return 'Emotional Distress';
      case AlertType.toxicBehaviorPattern:
        return 'Toxic Behavior Pattern';
      case AlertType.suspiciousContactsPattern:
        return 'Suspicious Contacts';
      case AlertType.predictiveThreat:
        return 'Predictive Threat';
      case AlertType.general:
        return 'General Alert';
    }
  }

  String get value {
    return name;
  }

  static AlertType fromString(String value) {
    return AlertType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AlertType.general,
    );
  }
}

