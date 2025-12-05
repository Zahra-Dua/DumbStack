Essence of Security Rules for Module 4

- Parent can only read/write inside their own subtree users/{parentId}
- Child app can only write its own lastLocation, locations, and zoneEvents, and cannot read other children
- Only parent (role==parent) may create/update/delete geofences
- A Cloud Function enforces parent-child link for privileged writes if needed

Sample rules (sketch, refine in Firebase console):

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    function isParent(parentId) { return isSignedIn() && request.auth.token.role == 'parent' && request.auth.uid == parentId; }
    function isChild(childId) { return isSignedIn() && request.auth.token.role == 'child' && request.auth.uid == childId; }

    match /users/{parentId} {
      allow read, write: if isParent(parentId);

      match /children/{childId} {
        allow read: if isParent(parentId);

        // child device writes
        match /lastLocation { allow write: if isChild(childId); }
        match /locations/{autoId} { allow create: if isChild(childId); }
        match /zoneEvents/{eventId} { allow create: if isChild(childId); }

        // geofences are parent-managed
        match /geofences/{zoneId} {
          allow read: if isParent(parentId);
          allow create, update, delete: if isParent(parentId);
        }
      }
    }
  }
}