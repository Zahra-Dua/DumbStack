# Model Name Troubleshooting Guide

## Current Issue
All model names failing with: "not found for API version v1beta"

## Tried Models (All Failed)
1. ❌ `gemini-1.5-flash`
2. ❌ `gemini-pro`
3. ❌ `gemini-1.5-pro`

## Current Fix
Using: `gemini-2.5-flash` (without `models/` prefix)

## If Still Not Working - Try These:

### Option 1: Update Package
```yaml
# pubspec.yaml
google_generative_ai: ^0.5.0  # Try latest version
```

### Option 2: Use Different Model Names
In `ai_chat_service.dart` line 42, try these one by one:

```dart
model: 'gemini-2.5-flash',        // Current
model: 'gemini-2.0-flash-exp',    // Alternative 1
model: 'gemini-1.5-flash-latest', // Alternative 2
model: 'gemini-pro',               // Alternative 3
```

### Option 3: Check API Key Permissions
- Verify API key has access to Gemini models
- Check Google AI Studio for available models
- Ensure API key is not restricted

### Option 4: Use Backend API Instead
If Flutter package doesn't work, use HTTP calls to your backend:
- Backend already working with `models/gemini-2.5-flash`
- Make HTTP POST to backend `/ai/query` endpoint

## Next Steps
1. Test with `gemini-2.5-flash`
2. If fails, try package update
3. If still fails, consider using backend API via HTTP

