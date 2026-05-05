# Real Firebase Rollout

This repo is now shaped for the real business flow, but it is not fully live yet because these Firebase app files are still missing from the workspace:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Until those exist, the app cannot actually connect to your Firebase project.

## 1. Flutter packages

Add these packages to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.15.2
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.10
  cloud_functions: ^5.6.0
```

Then run:

```bash
flutter pub get
flutterfire configure
```

## 2. Real auth flow

Use Firebase Email/Password Auth for every real account.

### Business account

The business owner creates:

- business name
- owner name
- email
- password
- state
- 4-digit PIN

After `createUserWithEmailAndPassword`, create:

- `users/{uid}`
- `teams/{teamId}`

### Employee account

Employees should only create an account if a pending invite already exists for their email.

After `createUserWithEmailAndPassword`, your app should:

1. query `invites` for a pending invite matching the email
2. attach the employee to that team
3. create `users/{uid}`
4. mark invite as accepted

## 3. Firestore collections

Create documents in these collections:

- `users`
- `teams`
- `invites`
- `shifts`
- `timeEntries`
- `mail` if using Firebase Trigger Email extension

### `users/{uid}`

```json
{
  "fullName": "Eli Smith",
  "email": "eli@example.com",
  "teamId": "team_abc123",
  "role": "employee",
  "stateCode": "IL",
  "hourlyRate": 21.2,
  "pinHash": "HASH_ONLY",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### `teams/{teamId}`

```json
{
  "name": "Riverfront Market",
  "ownerUserId": "uid_owner",
  "managerIds": ["uid_owner", "uid_manager2"],
  "memberIds": ["uid_owner", "uid_employee1"],
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### `invites/{inviteId}`

```json
{
  "teamId": "team_abc123",
  "teamName": "Riverfront Market",
  "email": "employee@example.com",
  "role": "employee",
  "status": "pending",
  "invitedByUserId": "uid_owner",
  "acceptedByUserId": null,
  "createdAt": "serverTimestamp",
  "acceptedAt": null
}
```

### `shifts/{shiftId}`

```json
{
  "teamId": "team_abc123",
  "assignedUserId": "uid_employee1",
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
  "teamId": "team_abc123",
  "userId": "uid_employee1",
  "clockIn": "timestamp",
  "clockOut": null,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

## 4. Email invitation link

The cleanest Firebase-native option is the Trigger Email extension.

Official docs:

- [Trigger Email extension](https://firebase.google.com/docs/extensions/official/firestore-send-email)

### Setup

1. Install the `firestore-send-email` extension in Firebase.
2. Configure a collection named `mail`.
3. When a business creates an invite, also write a `mail/{id}` document.

Example `mail` document:

```json
{
  "to": "employee@example.com",
  "message": {
    "subject": "You have been invited to join Riverfront Market",
    "html": "<p>You were invited to join Riverfront Market.</p><p>Create your account using this email address.</p>"
  }
}
```

### Better link pattern

Put a deep link or web link in that email like:

```text
https://yourapp.example.com/join?inviteId=abc123
```

Then:

1. employee taps the link
2. app or landing page reads `inviteId`
3. app pre-fills the invited email
4. employee creates Firebase Auth account
5. registration claims the invite and joins the team

## 5. PIN setup recommendation

The employee should set their PIN during account creation, not after joining.

Why:

- the user only sets it once
- it works immediately for workplace re-entry
- the same PIN can be used after the invite is accepted

Do not store the PIN as plain text in production.

Recommended production approach:

1. user creates PIN in app
2. app sends PIN to trusted backend or Cloud Function
3. backend stores only `pinHash`
4. workplace sign-in checks entered PIN against the hash

## 6. Cross-device sync

For real sync across devices logged into the same account:

- store all shift, user, invite, and clock data in Firestore
- use snapshot listeners for all active workplace data
- keep open time entries as documents with `clockOut: null`

That is what makes this work:

- employee clocks in on one device
- signs out
- signs in later on same or another device
- app reads the open `timeEntries` document
- employee is still shown as clocked in until they press clock out

## 7. Security rules shape

Use Firestore rules so:

- a signed-in user can read only their own user doc unless they are a manager in the same team
- only managers or business owners can create invites
- only managers or business owners can edit roles and hourly rates
- employees can request shift drops only for their own assigned shifts
- employees can create and update only their own time entries
- managers can read all time entries inside their team

Use the rules file in:

- [firestore_collections_and_rules.md](/Users/marcusrodriguez/UI_Final_Project/docs/firestore_collections_and_rules.md)

Official Firebase docs used:

- [Flutter email/password auth](https://firebase.google.com/docs/auth/flutter/password-auth)
- [Firestore realtime listeners](https://firebase.google.com/docs/firestore/query-data/listen)
- [Firestore offline sync](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Rules + auth](https://firebase.google.com/docs/rules/rules-and-auth)
- [Custom claims](https://firebase.google.com/docs/auth/admin/custom-claims)
