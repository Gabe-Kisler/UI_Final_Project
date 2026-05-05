# Firebase Flutter Setup

Use Firebase for the real production backend behind the current Flutter UI.

## 1. Add packages

Add these to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.15.0
  firebase_auth: ^5.6.0
  cloud_firestore: ^5.6.9
  cloud_functions: ^5.6.0
```

Then run:

```bash
flutter pub get
flutterfire configure
```

`flutterfire configure` creates `firebase_options.dart`.

## 2. Initialize Firebase

In `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ShiftSyncApp());
}
```

## 3. Authentication model

Use `FirebaseAuth` email/password only for account creation and secure account ownership.

- Employee creates account with:
  - email
  - password
  - 4-digit PIN
  - state
- Store employee profile in Firestore after signup
- Store only a hashed PIN in production

Recommended collections:

- `teams/{teamId}`
- `users/{userId}`
- `invites/{inviteId}`
- `shifts/{shiftId}`
- `timeEntries/{timeEntryId}`

## 4. Manager invite flow

Manager sends an invite by email.

Store this in `invites/{inviteId}`:

- `teamId`
- `teamName`
- `email`
- `role`
- `hourlyRate`
- `status`
- `invitedByUserId`
- `sentAt`

Flow:

1. Manager enters employee email in the app.
2. App writes a pending invite to Firestore.
3. Cloud Function sends the invite email.
4. Employee creates the account using that same email.
5. After signup, app looks up the pending invite for that email.
6. App attaches the employee to the manager’s team automatically.
7. Invite status changes to `accepted`.

## 5. PIN-first workplace sign in

The current UI already matches this product flow:

1. User taps the workplace/team.
2. User taps their profile.
3. User enters their 4-digit PIN.
4. App opens their employee or manager dashboard.

For production security:

- keep Firebase Auth session active on the device
- use the PIN only as a local re-entry / workplace unlock step
- do not use the PIN as the only backend authentication credential

That gives you:

- secure Firebase identity
- fast employee re-entry with only the PIN
- proper access control for schedules, roles, hours, and pay

## 6. Firestore sync

Listen to these collections with snapshots:

- current team
- team users
- team invites
- team shifts
- user time entries

That is how account changes, schedules, approvals, worked hours, and paycheck previews stay updated across all devices.
