/// Chatbot Prompt Configuration
/// 
/// Yahan apni custom prompt add kar sakte hain.
/// API key: lib/features/chatbot/data/config/chatbot_api_config.dart mein add karein
class ChatbotPromptConfig {
  /// Main system prompt for the AI assistant
  static const String systemPrompt = """
You are SafeNest AI — a smart parental assistant.

Your job:

- Read the child's real usage data provided below.

- Understand what the parent is asking.

- Give accurate, supportive, and simple explanations.

- Provide helpful guidance, suggestions, warnings, and tips for the parent.

Rules:

1. Always answer using the child's data from Firebase.

2. If data is missing, say: "Is child ka data available nahi mila."

3. Parent can ask in Urdu, English, or mix — respond in the same style.

4. Keep answers short, clear, and parent-friendly.

5. If parent asks for suggestions → give actionable steps (2–3).

6. You must analyze:

   - screen time

   - app usage

   - location

   - safe zones

   - calls/SMS activity (if provided)

   - device habits

   - flagged messages (if any) — tell parent which numbers sent flagged messages and why

7. Never make up fake data.

8. For flagged messages: If parent asks about flagged SMS or suspicious messages, provide:
   - Which phone numbers sent flagged messages
   - What type of content was flagged (toxicity label)
   - When these messages were received
   - Actionable advice on how to handle this

Response Style:
- Multi-language support: Respond in the same language/style as parent's question
- If parent asks in Urdu/Hindi mix → respond in Urdu/Hindi mix
- If parent asks in English → respond in English
- Be natural and conversational
- Use simple, clear language that parents can understand
""";

  /// Context builder for child data
  static String buildChildDataContext(Map<String, dynamic>? childData) {
    if (childData == null || childData.isEmpty) {
      return 'No child data available. Provide general advice based on best practices.';
    }

    final buffer = StringBuffer();
    
    // Profile
    if (childData['profile'] != null) {
      final profile = childData['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        buffer.writeln('=== CHILD PROFILE ===');
        buffer.writeln('Name: ${profile['name'] ?? 'N/A'}');
        buffer.writeln('Age: ${profile['age'] ?? 'N/A'}');
        buffer.writeln('Gender: ${profile['gender'] ?? 'N/A'}');
        if (profile['hobbies'] != null) {
          buffer.writeln('Hobbies: ${profile['hobbies']}');
        }
        buffer.writeln('');
      }
    }

    // App Usage
    if (childData['appUsage'] != null && (childData['appUsage'] as List).isNotEmpty) {
      buffer.writeln('=== APP USAGE ===');
      final appUsage = childData['appUsage'] as List;
      buffer.writeln('Total apps tracked: ${appUsage.length}');
      // Show top 5 apps
      final topApps = appUsage.take(5).map((app) {
        final name = app['appName'] ?? 'Unknown';
        final duration = app['usageDuration'] ?? 0;
        return '$name: ${_formatDuration(duration)}';
      }).join(', ');
      buffer.writeln('Top apps: $topApps');
      buffer.writeln('');
    }

    // Notifications
    if (childData['notifications'] != null && (childData['notifications'] as List).isNotEmpty) {
      buffer.writeln('=== RECENT NOTIFICATIONS ===');
      buffer.writeln('Total notifications: ${(childData['notifications'] as List).length}');
      buffer.writeln('');
    }

    // Messages
    if (childData['messages'] != null && (childData['messages'] as List).isNotEmpty) {
      buffer.writeln('=== MESSAGES ===');
      buffer.writeln('Total messages: ${(childData['messages'] as List).length}');
      
      // Check for flagged messages in regular messages
      final flaggedInMessages = (childData['messages'] as List)
          .where((msg) => (msg['flag'] != null && msg['flag'] != 0) || 
                          (msg['toxLabel'] != null && msg['toxLabel'] != 'safe'))
          .toList();
      if (flaggedInMessages.isNotEmpty) {
        buffer.writeln('⚠️ Flagged messages in regular messages: ${flaggedInMessages.length}');
        for (var msg in flaggedInMessages.take(3)) {
          final sender = msg['metadata']?['phoneNumber'] ?? msg['senderId'] ?? 'Unknown';
          final label = msg['toxLabel'] ?? 'suspicious';
          buffer.writeln('  - From: $sender, Type: $label');
        }
      }
      buffer.writeln('');
    }

    // Flagged Messages (separate collection)
    if (childData['flaggedMessages'] != null && (childData['flaggedMessages'] as List).isNotEmpty) {
      buffer.writeln('=== FLAGGED MESSAGES (SUSPICIOUS SMS) ===');
      final flagged = childData['flaggedMessages'] as List;
      buffer.writeln('Total flagged messages: ${flagged.length}');
      
      // Group by sender number
      final Map<String, List<Map<String, dynamic>>> bySender = {};
      for (var msg in flagged) {
        final sender = msg['sender'] ?? msg['metadata']?['phoneNumber'] ?? 'Unknown';
        if (!bySender.containsKey(sender)) {
          bySender[sender] = [];
        }
        bySender[sender]!.add(msg);
      }
      
      buffer.writeln('Flagged messages by phone number:');
      bySender.forEach((sender, msgs) {
        final label = msgs.first['tox_label'] ?? msgs.first['toxLabel'] ?? 'suspicious';
        final score = msgs.first['tox_score'] ?? msgs.first['toxScore'] ?? 0.0;
        buffer.writeln('  📱 $sender: ${msgs.length} message(s)');
        buffer.writeln('     Type: $label, Risk Score: $score');
        if (msgs.first['content'] != null) {
          final content = msgs.first['content'].toString();
          buffer.writeln('     Sample: ${content.length > 50 ? content.substring(0, 50) + "..." : content}');
        }
      });
      buffer.writeln('');
    }

    // Location (exact Firebase collection name: 'location' not 'locations')
    if (childData['location'] != null && (childData['location'] as List).isNotEmpty) {
      buffer.writeln('=== LOCATION DATA ===');
      final locationList = childData['location'] as List;
      buffer.writeln('Location points tracked: ${locationList.length}');
      
      // Separate current and history locations
      Map<String, dynamic>? currentLocation;
      try {
        currentLocation = locationList.firstWhere(
          (loc) => loc['type'] == 'current' || loc['id'] == 'current',
        ) as Map<String, dynamic>?;
      } catch (e) {
        currentLocation = null;
      }
      final historyLocations = locationList.where(
        (loc) => loc['type'] == 'history' || loc['id'] != 'current',
      ).toList();
      
      if (currentLocation != null) {
        final lat = currentLocation['latitude'] ?? 'N/A';
        final lng = currentLocation['longitude'] ?? 'N/A';
        final address = currentLocation['address'] ?? currentLocation['currentAddress'] ?? 'N/A';
        buffer.writeln('Current Location: Lat $lat, Lng $lng');
        buffer.writeln('Address: $address');
      }
      
      if (historyLocations.isNotEmpty) {
        buffer.writeln('History locations: ${historyLocations.length}');
      }
      buffer.writeln('');
    }

    // Safe Zones
    if (childData['safezones'] != null && (childData['safezones'] as List).isNotEmpty) {
      buffer.writeln('=== SAFE ZONES ===');
      buffer.writeln('Safe zones configured: ${(childData['safezones'] as List).length}');
      buffer.writeln('');
    }

    // Installed Apps
    if (childData['installedApps'] != null && (childData['installedApps'] as List).isNotEmpty) {
      buffer.writeln('=== INSTALLED APPS ===');
      buffer.writeln('Total installed apps: ${(childData['installedApps'] as List).length}');
      buffer.writeln('');
    }

    // Screen Time
    if (childData['screenTime'] != null && (childData['screenTime'] as List).isNotEmpty) {
      buffer.writeln('=== SCREEN TIME ===');
      final screenTime = childData['screenTime'] as List;
      buffer.writeln('Screen time records: ${screenTime.length}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Format duration in seconds to readable format
  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(1)}m';
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }
}

