# Firestore Collections And Rules

This is the recommended Firestore shape for the app as it works now.

## Collections

You do not need to manually create empty collections first. Firestore creates them when your app writes the first document.

Recommended top-level collections:

- `users/{uid}`
- `teams/{teamId}`
- `invites/{inviteId}`
- `shifts/{shiftId}`
- `timeEntries/{timeEntryId}`
- `mail/{mailId}` if you use the Firebase Trigger Email extension

## Document Shapes

### `users/{uid}`

```json
{
  "email": "eli@example.com",
  "fullName": "Eli Smith",
  "stateCode": "IL",
  "role": "employee",
  "teamId": "team_riverfront",
  "hourlyRate": 21.2,
  "pinHash": "HASHED_PIN_ONLY",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### `teams/{teamId}`

```json
{
  "name": "Riverfront Market",
  "managerIds": ["uid_manager_1"],
  "memberIds": ["uid_manager_1", "uid_employee_1"],
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### `invites/{inviteId}`

```json
{
  "teamId": "team_riverfront",
  "teamName": "Riverfront Market",
  "email": "newhire@example.com",
  "role": "employee",
  "status": "pending",
  "invitedByUserId": "uid_manager_1",
  "acceptedByUserId": null,
  "createdAt": "serverTimestamp",
  "acceptedAt": null
}
```

### `shifts/{shiftId}`

```json
{
  "teamId": "team_riverfront",
  "assignedUserId": "uid_employee_1",
  "roleName": "Cashier",
  "start": "timestamp",
  "end": "timestamp",
  "status": "scheduled",
  "requestedByUserId": null,
  "pickupCandidateUserId": null,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### `timeEntries/{timeEntryId}`

```json
{
  "teamId": "team_riverfront",
  "userId": "uid_employee_1",
  "clockIn": "timestamp",
  "clockOut": null,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

## Firestore Security Rules

Example starting point:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    function userDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid));
    }

    function isSelf(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }

    function isManager() {
      return isSignedIn() && userDoc().data.role == 'manager';
    }

    function isSameTeam(teamId) {
      return isSignedIn() && userDoc().data.teamId == teamId;
    }

    match /users/{uid} {
      allow read: if isSelf(uid) || (isManager() && isSameTeam(resource.data.teamId));

      allow create: if isSelf(uid);

      allow update: if
        isSelf(uid) &&
        request.resource.data.role == resource.data.role &&
        request.resource.data.hourlyRate == resource.data.hourlyRate &&
        request.resource.data.teamId == resource.data.teamId
        ||
        (isManager() && isSameTeam(resource.data.teamId));
    }

    match /teams/{teamId} {
      allow read: if isSameTeam(teamId);
      allow create: if isSignedIn();
      allow update: if isManager() && isSameTeam(teamId);
    }

    match /invites/{inviteId} {
      allow read: if isManager() && isSameTeam(resource.data.teamId);
      allow create: if isManager() && isSameTeam(request.resource.data.teamId);
      allow update: if isManager() && isSameTeam(resource.data.teamId);
    }

    match /shifts/{shiftId} {
      allow read: if isSameTeam(resource.data.teamId);

      allow create, delete: if isManager() && isSameTeam(request.resource.data.teamId);

      allow update: if
        (isManager() && isSameTeam(resource.data.teamId))
        ||
        (
          isSelf(resource.data.assignedUserId) &&
          isSameTeam(resource.data.teamId) &&
          request.resource.data.assignedUserId == resource.data.assignedUserId
        );
    }

    match /timeEntries/{timeEntryId} {
      allow read: if
        isSelf(resource.data.userId) ||
        (isManager() && isSameTeam(resource.data.teamId));

      allow create: if
        isSignedIn() &&
        request.resource.data.userId == request.auth.uid &&
        isSameTeam(request.resource.data.teamId);

      allow update: if
        isSelf(resource.data.userId) ||
        (isManager() && isSameTeam(resource.data.teamId));
    }
  }
}
```

## Sync Across Devices

To keep the same account synced everywhere:

- authenticate with the same Firebase Auth account on every device
- store all app state in Firestore, not only in local memory
- listen to Firestore snapshots for users, teams, shifts, invites, and time entries
- rely on Firestore offline persistence for reconnect sync

## PIN Recommendation

Do not store the PIN in plaintext.

Recommended:

1. User creates the PIN during account creation.
2. App sends the PIN to a trusted backend function.
3. Function stores only `pinHash`.
4. Workplace sign-in verifies the PIN against the stored hash.

That means the user should set the PIN during account creation, not after joining the team.
