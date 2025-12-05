# 🔐 Secrets Setup Guide

## ⚠️ Important Security Notice

GitHub detected API keys in your code and blocked the push. This is a **security feature** to protect your keys.

## ✅ Solution: Remove Hardcoded Keys

I've removed all hardcoded API keys and added them to `.gitignore`. Now you need to:

### **Step 1: Create Local Config Files**

Copy the example files and add your actual API keys:

```bash
# Chatbot API Key
cp lib/features/chatbot/data/config/chatbot_api_config.dart.example \
   lib/features/chatbot/data/config/chatbot_api_config.dart

# Safe Browsing API Key (if needed)
cp lib/features/url_tracking/data/services/safe_browsing_service.dart.example \
   lib/features/url_tracking/data/services/safe_browsing_service.dart
```

### **Step 2: Add Your API Keys**

#### **1. Chatbot API Key** (`chatbot_api_config.dart`)
```dart
static const String openaiApiKey = 'YOUR_ACTUAL_OPENAI_API_KEY';
```

#### **2. Safe Browsing API Key** (`safe_browsing_service.dart`)
```dart
static const String _apiKey = 'YOUR_ACTUAL_SAFE_BROWSING_API_KEY';
```

#### **3. Real URL Tracking** (`real_url_tracking_service.dart`)
```dart
final SafeBrowsingChecker _gsb = SafeBrowsingChecker(
  apiKey: 'YOUR_ACTUAL_SAFE_BROWSING_API_KEY'
);
```

### **Step 3: Verify .gitignore**

These files are now in `.gitignore`:
- ✅ `lib/features/chatbot/data/config/chatbot_api_config.dart`
- ✅ `lib/features/url_tracking/data/services/safe_browsing_service.dart`
- ✅ `*.secret.dart`
- ✅ `*.api_key.dart`
- ✅ `.env`

### **Step 4: Commit Changes**

```bash
# Add all changes (except ignored files)
git add .

# Commit
git commit -m "Remove hardcoded API keys, add to .gitignore"

# Push
git push origin main
```

## 📝 Files Changed

1. ✅ **`.gitignore`** - Added sensitive files
2. ✅ **`safe_browsing_service.dart`** - Removed hardcoded key
3. ✅ **`real_url_tracking_service.dart`** - Removed hardcoded key
4. ✅ **`url_tracking_service.dart`** - Removed hardcoded key
5. ✅ **`chatbot_api_config.dart`** - Already empty (good!)

## 🔑 Where to Get API Keys

### **OpenAI API Key:**
1. Go to: https://platform.openai.com/api-keys
2. Create new key
3. Copy and paste in `chatbot_api_config.dart`

### **Google Safe Browsing API Key:**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Enable "Safe Browsing API"
3. Create API key
4. Copy and paste in `safe_browsing_service.dart`

## ⚠️ Important Notes

1. **Never commit API keys** - They're now in `.gitignore`
2. **Use example files** - Copy from `.example` files
3. **Keep keys secure** - Don't share them publicly
4. **Rotate if exposed** - If a key was exposed, generate a new one

## ✅ After Setup

Once you've added your API keys locally:
- Files with keys won't be committed to Git
- GitHub won't block your pushes
- Your keys remain secure

## 🚨 If Keys Were Already Exposed

If your keys were already pushed to GitHub:
1. **Immediately revoke** the exposed keys
2. Generate **new keys**
3. Update your local config files
4. Consider using GitHub Secrets for CI/CD

