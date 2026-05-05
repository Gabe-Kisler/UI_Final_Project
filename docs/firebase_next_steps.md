# Firebase Next Steps

Your Firebase project is:

- `shiftsync-417b1`

## What to run locally

From your Flutter project root:

```bash
dart pub global activate flutterfire_cli
flutter pub get
flutterfire configure --project=shiftsync-417b1
```

That should generate:

- `lib/firebase_options.dart`
- platform Firebase app registrations

You also need the platform config files created/downloaded into the repo:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## After that

Once those files exist, update `lib/main.dart` to:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ShiftSyncApp());
}
```

## Firebase products this app needs

- `Firebase Authentication`
  - Email/password accounts for business owners and employees
- `Cloud Firestore`
  - users, teams, invites, shifts, time entries
- `Cloud Functions`
  - invite acceptance, PIN hashing/verification, email workflows
- `Trigger Email` extension
  - easiest way to send employee invite emails from Firestore

## Firestore collections

Create documents in:

- `users`
- `teams`
- `invites`
- `shifts`
- `timeEntries`
- `mail`

More detail is in:

- [firestore_collections_and_rules.md](/Users/marcusrodriguez/UI_Final_Project/docs/firestore_collections_and_rules.md)
- [real_firebase_rollout.md](/Users/marcusrodriguez/UI_Final_Project/docs/real_firebase_rollout.md)

## Recommended order

1. Run `flutterfire configure --project=shiftsync-417b1`
2. Confirm `lib/firebase_options.dart` exists
3. Add Android/iOS config files if they are not already created
4. Let me patch `main.dart` and replace the in-memory controller with real Firebase repositories
5. Then wire:
   - business account creation
   - employee invite acceptance
   - Firestore sync
   - real clock-in persistence
   - manager/employee permissions
