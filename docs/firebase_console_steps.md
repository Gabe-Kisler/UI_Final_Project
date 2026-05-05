# Firebase Console Steps

Project:

- `shiftsync-417b1`

## 1. Authentication

In Firebase Console:

1. Open `Authentication`
2. Open `Sign-in method`
3. Enable `Email/Password`
4. Save

Optional but recommended:

1. Open `Settings`
2. Add your production domain and localhost to `Authorized domains`

## 2. Web app registration

If `flutterfire configure --project=shiftsync-417b1` has not been run yet:

1. In project overview, click `Add app`
2. Choose `Web`
3. Register the app
4. Then still run:
   ```bash
   flutterfire configure --project=shiftsync-417b1
   ```

This is what creates `lib/firebase_options.dart` for Flutter.

## 3. Firestore

1. Open `Firestore Database`
2. Click `Create database`
3. Choose `Production mode`
4. Pick your region
5. Create database

Then open the `Rules` tab and paste the contents of:

- [firestore.rules](/Users/marcusrodriguez/UI_Final_Project/firestore.rules)

Then click `Publish`.

## 4. Cloud Functions

From your project root:

```bash
firebase init functions
```

Choose:

1. Existing project: `shiftsync-417b1`
2. `JavaScript`
3. Node `20`
4. `Yes` to install dependencies if prompted

Then replace the generated `functions/index.js` with:

- [functions/index.js](/Users/marcusrodriguez/UI_Final_Project/functions/index.js)

And make sure `functions/package.json` matches:

- [functions/package.json](/Users/marcusrodriguez/UI_Final_Project/functions/package.json)

Then deploy:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

## 5. Trigger Email extension

In Firebase Console:

1. Open `Extensions`
2. Search for `Trigger Email`
3. Install `firestore-send-email`
4. Choose collection name: `mail`
5. Complete the email provider setup it asks for

That will let `createTeamInvite` send employee invite emails automatically by writing a Firestore `mail` document.

## 6. App Check for web

Recommended for security:

1. Open `App Check`
2. Register your web app
3. Choose reCAPTCHA v3
4. Add your site key
5. Enable enforcement later after local testing works

## 7. What each function does

After deploy, you will have:

- `setSecurePin`
  - hashes and stores the 4-digit PIN
- `verifySecurePin`
  - verifies the entered PIN
- `createTeamInvite`
  - creates invite doc and sends employee email
- `acceptTeamInvite`
  - joins the signed-in employee to the invited team

## 8. Recommended rollout order

1. Run `flutterfire configure --project=shiftsync-417b1`
2. Create Firestore database
3. Publish Firestore rules
4. Initialize Functions
5. Deploy functions
6. Install Trigger Email extension
7. Add App Check
8. Then wire the Flutter app to call these functions
