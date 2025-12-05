# Gemini Model Fix

## Issue
Error: `models/gemini-1.5-flash is not found for API version v1beta`

## Solution
Changed model name from `gemini-1.5-flash` to `gemini-pro`

## File Changed
`lib/features/chatbot/data/services/ai_chat_service.dart` - Line 40

## Alternative Models (if gemini-pro doesn't work)
1. `gemini-pro` ✅ (Current - most stable)
2. `gemini-1.5-pro` (If gemini-pro doesn't work)
3. `gemini-2.0-flash-exp` (Experimental)

## How to Test
1. Restart the app
2. Open chatbot
3. Send a message
4. Should work now!

## If Still Not Working
Check:
- API key is valid
- Internet connection
- Gemini API quota not exceeded
- Try `gemini-1.5-pro` as alternative

