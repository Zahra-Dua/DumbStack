# 🚀 Cloud Function Deployment Guide

## Step-by-Step Instructions to Deploy `sendNotification` Function

---

## 📋 Prerequisites

1. ✅ Firebase CLI installed: `npm install -g firebase-tools`
2. ✅ Firebase project initialized
3. ✅ Node.js installed (v14 or higher)
4. ✅ Firebase project has Blaze plan (required for Cloud Functions)

---

## 🔧 Step 1: Initialize Firebase Functions

```bash
# Navigate to project root
cd D:\parental-app-Tuesday-main

# Initialize Firebase (if not already done)
firebase init functions

# Select:
# - Use existing project (select your Firebase project)
# - Language: JavaScript
# - ESLint: Yes (optional)
# - Install dependencies: Yes
```

---

## 📁 Step 2: Setup Functions Folder Structure

Your functions folder should look like this:

```
functions/
├── index.js          (Cloud Function code)
├── package.json       (Dependencies)
└── .gitignore
```

---

## 📝 Step 3: Copy Cloud Function Code

1. Copy content from `firebase_cloud_function_sendNotification.js`
2. Paste into `functions/index.js`
3. Replace entire file content

---

## 📦 Step 4: Install Dependencies

```bash
cd functions
npm install firebase-functions firebase-admin
```

**Expected output:**
```
+ firebase-functions@4.x.x
+ firebase-admin@11.x.x
```

---

## ✅ Step 5: Verify package.json

Your `functions/package.json` should have:

```json
{
  "name": "functions",
  "description": "Cloud Functions for SafeNest App",
  "scripts": {
    "lint": "eslint .",
    "serve": "firebase emulators:start --only functions",
    "shell": "firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^11.0.0",
    "firebase-functions": "^4.0.0"
  },
  "devDependencies": {
    "eslint": "^8.15.0",
    "eslint-config-google": "^0.14.0"
  },
  "private": true
}
```

---

## 🚀 Step 6: Deploy Function

```bash
# From project root
firebase deploy --only functions:sendNotification
```

**Expected output:**
```
=== Deploying to 'your-project-id'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudresourcemanager.googleapis.com is enabled...
✓  functions: required APIs are enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading...
✓  functions: sendNotification function deployed successfully.

✔  Deploy complete!
```

---

## 🧪 Step 7: Test Function

### Option 1: Test via Firebase Console

1. Go to Firebase Console → Functions
2. Click on `sendNotification`
3. Click "Test" tab
4. Enter test data:

```json
{
  "data": {
    "token": "YOUR_PARENT_FCM_TOKEN",
    "title": "Test Notification",
    "body": "This is a test notification",
    "data": {
      "alertType": "sos",
      "childId": "test-child-id"
    },
    "priority": "high"
  }
}
```

5. Click "Test Function"
6. Check logs for success/error

### Option 2: Test via Flutter App

1. Send SOS alert from child app
2. Check Firebase Console → Functions → Logs
3. Verify notification received on parent device

---

## 📊 Step 8: Verify Deployment

### Check Function Status:

```bash
firebase functions:list
```

**Expected output:**
```
Function: sendNotification
Status: Active
Trigger: HTTPS Callable
```

### Check Function Logs:

```bash
firebase functions:log --only sendNotification
```

---

## 🔍 Troubleshooting

### Issue 1: "Functions require Blaze plan"

**Solution:**
- Upgrade Firebase project to Blaze plan
- Go to Firebase Console → Project Settings → Usage and Billing
- Upgrade to Blaze plan (pay-as-you-go)

### Issue 2: "Permission denied"

**Solution:**
```bash
firebase login
# Re-authenticate with Firebase account
```

### Issue 3: "Module not found: firebase-admin"

**Solution:**
```bash
cd functions
rm -rf node_modules package-lock.json
npm install
```

### Issue 4: "Function deployment failed"

**Solution:**
1. Check function code for syntax errors
2. Verify Node.js version (should be 18)
3. Check Firebase Console → Functions → Logs for errors

---

## 📝 Function Configuration

### Update Function Timeout (Optional):

In `functions/index.js`, add:

```javascript
exports.sendNotification = functions
  .runWith({
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .https.onCall(async (data, context) => {
    // ... function code
  });
```

### Update Function Region (Optional):

```javascript
exports.sendNotification = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    // ... function code
  });
```

---

## 🔐 Security: Authentication (Optional)

If you want to restrict function access:

```javascript
exports.sendNotification = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Function must be called while authenticated.'
    );
  }
  
  // ... rest of function code
});
```

---

## 📈 Monitoring

### View Function Metrics:

1. Firebase Console → Functions → `sendNotification`
2. View:
   - Invocations (total calls)
   - Errors (failed calls)
   - Execution time
   - Memory usage

### Set Up Alerts:

1. Firebase Console → Functions → `sendNotification` → Alerts
2. Configure:
   - Error rate threshold
   - Execution time threshold
   - Memory usage threshold

---

## ✅ Verification Checklist

- [ ] Firebase CLI installed
- [ ] Firebase project initialized
- [ ] Functions folder created
- [ ] Dependencies installed
- [ ] Function code copied
- [ ] Function deployed successfully
- [ ] Function tested via console
- [ ] Function tested via app
- [ ] Notifications received on device
- [ ] Logs checked for errors

---

## 🎯 Next Steps

After deployment:

1. ✅ Test SOS alert from child app
2. ✅ Verify notification received on parent device
3. ✅ Check Firebase Console → Functions → Logs
4. ✅ Monitor function performance
5. ✅ Set up alerts for errors

---

## 📞 Support

If you encounter issues:

1. Check Firebase Console → Functions → Logs
2. Check function code for syntax errors
3. Verify FCM token is valid
4. Check Firebase project billing (Blaze plan required)

---

**Last Updated:** $(date)
**Status:** Ready for Deployment

