/**
 * Cloud Function: Send FCM notification when URL is blocked
 * 
 * Deploy this to Firebase Cloud Functions:
 * firebase deploy --only functions:onUrlBlocked
 * 
 * Prerequisites:
 * 1. Enable Cloud Functions in Firebase Console
 * 2. Install dependencies: npm install firebase-functions firebase-admin
 * 3. Set up service account with FCM permissions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Triggered when a new block rule is created
 * Sends FCM data message to child device
 */
exports.onUrlBlocked = functions.firestore
  .document('parents/{parentId}/children/{childId}/blockedUrls/{ruleId}')
  .onCreate(async (snap, context) => {
    const ruleData = snap.data();
    const { parentId, childId } = context.params;

    console.log(`🔔 URL blocked: ${ruleData.url} for child ${childId}`);

    try {
      // Get child's FCM token
      const childDoc = await admin.firestore()
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .get();

      if (!childDoc.exists) {
        console.log(`⚠️ Child document not found: ${childId}`);
        return null;
      }

      const childData = childDoc.data();
      const fcmToken = childData?.fcmToken;

      if (!fcmToken) {
        console.log(`⚠️ FCM token not found for child ${childId}`);
        return null;
      }

      // Prepare FCM data message
      const message = {
        token: fcmToken,
        data: {
          type: 'blockRulesUpdated',
          action: 'refresh',
          url: ruleData.url,
          ruleId: snap.id,
          timestamp: Date.now().toString(),
        },
        android: {
          priority: 'high',
          data: {
            type: 'blockRulesUpdated',
            action: 'refresh',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10', // High priority
            'apns-push-type': 'background',
          },
          payload: {
            aps: {
              'content-available': 1, // Wake app in background (iOS)
            },
          },
        },
        // Optional: Add notification for foreground display
        notification: {
          title: 'URL Blocked',
          body: `A new URL has been blocked: ${ruleData.url}`,
        },
      };

      // Send FCM message
      const response = await admin.messaging().send(message);
      console.log(`✅ FCM notification sent successfully: ${response}`);

      return { success: true, messageId: response };
    } catch (error) {
      console.error(`❌ Error sending FCM notification: ${error}`);
      throw error;
    }
  });

/**
 * Triggered when block rule is deleted (unblocked)
 */
exports.onUrlUnblocked = functions.firestore
  .document('parents/{parentId}/children/{childId}/blockedUrls/{ruleId}')
  .onDelete(async (snap, context) => {
    const { parentId, childId } = context.params;

    console.log(`🔓 URL unblocked for child ${childId}`);

    try {
      const childDoc = await admin.firestore()
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .get();

      if (!childDoc.exists) return null;

      const childData = childDoc.data();
      const fcmToken = childData?.fcmToken;

      if (!fcmToken) return null;

      const message = {
        token: fcmToken,
        data: {
          type: 'blockRulesUpdated',
          action: 'refresh',
        },
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'background',
          },
          payload: {
            aps: {
              'content-available': 1,
            },
          },
        },
      };

      await admin.messaging().send(message);
      console.log(`✅ Unblock FCM notification sent`);
      return { success: true };
    } catch (error) {
      console.error(`❌ Error sending unblock FCM: ${error}`);
      return null;
    }
  });

