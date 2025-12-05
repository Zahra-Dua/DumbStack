/**
 * Firebase Cloud Function: sendNotification
 * 
 * This function sends FCM push notifications to parent devices
 * 
 * Deployment:
 * 1. Create functions folder: mkdir functions
 * 2. cd functions
 * 3. npm init -y
 * 4. npm install firebase-functions firebase-admin
 * 5. Copy this file to functions/index.js
 * 6. firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function: sendNotification
 * 
 * Sends FCM push notification to a specific device token
 * 
 * @param {Object} data - Request data
 * @param {string} data.token - FCM device token
 * @param {string} data.title - Notification title
 * @param {string} data.body - Notification body
 * @param {Object} data.data - Additional data payload
 * @param {string} data.priority - 'high' or 'normal'
 * @param {Object} context - Firebase callable function context
 * @returns {Promise<Object>} Success response with messageId
 */
exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    // Validate required parameters
    const { token, title, body, data: notificationData, priority } = data;
    
    if (!token) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameter: token'
      );
    }
    
    if (!title) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameter: title'
      );
    }
    
    if (!body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameter: body'
      );
    }

    console.log('📤 Sending notification:', {
      token: token.substring(0, 20) + '...',
      title,
      body,
      priority: priority || 'normal',
    });

    // Convert notification data to strings (FCM requirement)
    const dataPayload = {};
    if (notificationData && typeof notificationData === 'object') {
      for (const [key, value] of Object.entries(notificationData)) {
        dataPayload[key] = String(value);
      }
    }

    // Build FCM message
    const message = {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: dataPayload,
      android: {
        priority: priority === 'high' ? 'high' : 'normal',
        notification: {
          channelId: 'high_importance_channel',
          sound: 'default',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
          defaultLightSettings: true,
        },
      },
      apns: {
        headers: {
          'apns-priority': priority === 'high' ? '10' : '5',
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
      },
      webpush: {
        notification: {
          title: title,
          body: body,
          icon: '/icon.png',
          badge: '/badge.png',
        },
      },
    };

    // Send notification via FCM
    const response = await admin.messaging().send(message);
    
    console.log('✅ Successfully sent notification:', {
      messageId: response,
      token: token.substring(0, 20) + '...',
    });
    
    return {
      success: true,
      messageId: response,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    
    // Handle specific FCM errors
    if (error.code === 'messaging/invalid-registration-token') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid FCM token. Token may be expired or invalid.'
      );
    }
    
    if (error.code === 'messaging/registration-token-not-registered') {
      throw new functions.https.HttpsError(
        'not-found',
        'FCM token not registered. Device may have uninstalled the app.'
      );
    }
    
    // Generic error
    throw new functions.https.HttpsError(
      'internal',
      `Failed to send notification: ${error.message}`
    );
  }
});

/**
 * Optional: Batch notification sender (for multiple tokens)
 * 
 * Uncomment if you need to send notifications to multiple devices
 */
/*
exports.sendBatchNotifications = functions.https.onCall(async (data, context) => {
  try {
    const { tokens, title, body, data: notificationData } = data;
    
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'tokens must be a non-empty array'
      );
    }
    
    // Convert data to strings
    const dataPayload = {};
    if (notificationData && typeof notificationData === 'object') {
      for (const [key, value] of Object.entries(notificationData)) {
        dataPayload[key] = String(value);
      }
    }
    
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: dataPayload,
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
          sound: 'default',
          priority: 'high',
        },
      },
    };
    
    // Send to multiple tokens
    const response = await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      ...message,
    });
    
    console.log(`✅ Sent ${response.successCount} notifications, ${response.failureCount} failed`);
    
    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses,
    };
  } catch (error) {
    console.error('❌ Error sending batch notifications:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to send batch notifications: ${error.message}`
    );
  }
});
*/

