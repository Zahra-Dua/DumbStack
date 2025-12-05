# AI Recommendations and Insights - Chatbot Module

## 📋 Overview

Complete chatbot system for SafeNest that helps parents understand their children's digital activity through AI-powered insights and recommendations.

## 🏗️ Module Structure

```
lib/features/chatbot/
├── data/
│   ├── config/
│   │   ├── chatbot_api_config.dart      # ⚠️ API KEY YAHAN ADD KAREIN
│   │   └── chatbot_prompt_config.dart   # Custom prompt configuration
│   └── services/
│       ├── firebase_child_data_service.dart  # Firebase data fetching
│       ├── ai_chat_service.dart             # Gemini AI integration
│       └── chatbot_service.dart              # Main chatbot service
└── presentation/
    └── pages/
        └── chatbot_screen.dart              # Chat UI screen
```

## 🔑 API Key Setup

**IMPORTANT:** Pehle API key add karein!

1. Google AI Studio se API key generate karein: https://makersuite.google.com/app/apikey
2. File open karein: `lib/features/chatbot/data/config/chatbot_api_config.dart`
3. Line 10 par apni API key paste karein:
   ```dart
   static const String geminiApiKey = 'YOUR_API_KEY_HERE';
   ```
4. File save karein

## 🚀 Features

✅ **Auto Child Detection** - Message se child ka name automatically detect karta hai  
✅ **Complete Data Fetching** - Firebase se saara child data fetch karta hai  
✅ **Real-time Chat** - Streaming responses with typing animation  
✅ **Chat History** - Firebase mein chat history save hoti hai  
✅ **Multi-language Support** - English aur Urdu/Hindi dono support  
✅ **Smart Context** - Child data ke basis par personalized responses  

## 📱 Usage

### Parent Home Screen se:
1. Home screen par floating button (🤖) par click karein
2. Chatbot screen open hoga
3. Message type karein aur send karein

### Example Questions:
- "Shayan ka screen time kitna hai?"
- "Ahmed ki apps kya hain?"
- "Fatima ki location kya hai?"
- "Mere bachon ka digital wellbeing kaise improve kar sakta hoon?"

## 🔧 Configuration

### Custom Prompt
File: `lib/features/chatbot/data/config/chatbot_prompt_config.dart`

Yahan apni custom prompt add/modify kar sakte hain:
- System prompt
- Response style
- Guidelines
- Language preferences

### Firebase Paths
Current structure:
- `parents/{parentId}/children/{childId}` - Child profile
- `parents/{parentId}/children/{childId}/appUsage` - App usage
- `parents/{parentId}/children/{childId}/notifications` - Notifications
- `parents/{parentId}/children/{childId}/messages` - Messages
- `parents/{parentId}/children/{childId}/locations` - Locations
- `parents/{parentId}/children/{childId}/safezones` - Safe zones
- `parents/{parentId}/children/{childId}/installedApps` - Installed apps
- `parents/{parentId}/children/{childId}/screenTime` - Screen time

## 📊 Data Flow

1. **User sends message** → Chatbot screen
2. **Extract child name** → From message (if mentioned)
3. **Find childId** → Firebase search by name
4. **Fetch child data** → All collections from Firebase
5. **Build context** → Format data for AI
6. **Get AI response** → Gemini API call
7. **Stream response** → Real-time typing effect
8. **Save to history** → Firebase chatHistory collection

## 🎨 UI Features

- Modern chat interface
- Message bubbles (user vs AI)
- Typing indicator
- Scroll to bottom
- Empty state with helpful message
- Loading states

## 🔐 Security

- Only parent's own children data accessible
- Parent ID verification
- API key stored in config (not in code)
- Firebase security rules should be configured

## 📝 Notes

- Chatbot automatically finds child by name from message
- If child not found, provides general advice
- All responses saved to Firebase for history
- Supports both streaming and non-streaming responses

## 🐛 Troubleshooting

**API Key Error:**
- Check `chatbot_api_config.dart` mein API key add hai
- Verify API key valid hai
- Check internet connection

**No Child Data:**
- Verify Firebase structure correct hai
- Check parent ID and child ID
- Ensure data exists in Firebase

**Chat Not Loading:**
- Check Firebase connection
- Verify user is logged in
- Check console for errors

---

**Module Name:** AI Recommendations and Insights  
**Status:** ✅ Complete and Ready  
**Last Updated:** 2024

