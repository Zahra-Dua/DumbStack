// Firebase cleanup script to remove wrong children collection
// Run this in Firebase console or with admin SDK

const admin = require('firebase-admin');

// Initialize Firebase Admin (you'll need to add your service account key)
// admin.initializeApp({
//   credential: admin.credential.applicationDefault(),
//   databaseURL: "https://your-project-id.firebaseio.com"
// });

const db = admin.firestore();

async function cleanupWrongChildrenCollection() {
  try {
    console.log('🧹 Starting cleanup of wrong children collection...');
    
    // Check if children collection exists at root level
    const childrenSnapshot = await db.collection('children').get();
    
    if (childrenSnapshot.empty) {
      console.log('✅ No children collection found at root level. Structure is correct.');
      return;
    }
    
    console.log(`❌ Found ${childrenSnapshot.size} documents in wrong children collection`);
    
    // Move each child to the correct parent's subcollection
    for (const childDoc of childrenSnapshot.docs) {
      const childData = childDoc.data();
      const childId = childDoc.id;
      const parentId = childData.parentId;
      
      if (!parentId) {
        console.log(`⚠️ Child ${childId} has no parentId, skipping...`);
        continue;
      }
      
      console.log(`🔄 Moving child ${childId} to parent ${parentId}...`);
      
      // Create child in correct location
      await db.collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .set(childData);
      
      // Update parent's childrenIds array
      await db.collection('parents')
        .doc(parentId)
        .update({
          childrenIds: admin.firestore.FieldValue.arrayUnion(childId)
        });
      
      // Delete from wrong location
      await childDoc.ref.delete();
      
      console.log(`✅ Moved child ${childId} successfully`);
    }
    
    console.log('🎉 Cleanup completed successfully!');
    
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  }
}

// Uncomment to run
// cleanupWrongChildrenCollection();
