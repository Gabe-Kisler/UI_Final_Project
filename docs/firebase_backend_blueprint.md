# Firebase Backend Blueprint

This Flutter app now has a shared state model for:

- email/password account registration
- 4-digit workplace PIN unlock
- manager email invites
- employee roles
- schedules, duplicates, edits, and approvals
- clock-in / clock-out time entries
- paycheck previews based on hours and state withholding

## Recommended Firebase Services

- `Firebase Authentication`
  - Email/password sign-in for manager and employee accounts
- `Cloud Firestore`
  - Real-time sync for users, teams, invites, shifts, approvals, and time entries
- `Cloud Functions`
  - Invite email delivery
  - PIN hashing / verification workflow
  - Payroll preview recalculation jobs if needed
- `Firebase App Check`
  - Helps protect backend resources from unauthorized clients

## Collections

- `teams/{teamId}`
  - `name`
  - `managerIds`
  - `memberIds`
- `users/{userId}`
  - `teamId`
  - `fullName`
  - `email`
  - `role`
  - `stateCode`
  - `hourlyRate`
  - `pinHash`
- `invites/{inviteId}`
  - `teamId`
  - `email`
  - `role`
  - `hourlyRate`
  - `status`
  - `invitedByUserId`
  - `sentAt`
- `shifts/{shiftId}`
  - `teamId`
  - `assignedUserId`
  - `roleName`
  - `start`
  - `end`
  - `status`
  - `requestedByUserId`
  - `pickupCandidateUserId`
- `timeEntries/{entryId}`
  - `teamId`
  - `userId`
  - `clockIn`
  - `clockOut`

## Security Rules Shape

Use Firestore rules so:

- signed-in users can only read their own user profile unless they are a team manager
- employees can only read shifts and time entries in their own team
- employees can only edit their own drop request fields
- only managers can:
  - create invites
  - update employee roles
  - create/edit/duplicate shifts
  - approve drop and pickup requests
- time entries can only be written by the owning user, except manager correction flows

## PIN Security

Do not store the 4-digit PIN in plaintext in production.

Recommended production flow:

1. User creates PIN locally.
2. App sends PIN to a callable Cloud Function over HTTPS.
3. Function salts + hashes the PIN and stores only `pinHash`.
4. PIN verification is performed with the same function or a secure backend endpoint.

## Email Invite Flow

1. Manager creates invite in app.
2. Cloud Function sends an email link to the invited address.
3. Employee registers with that email.
4. Registration checks for a pending invite and attaches the employee to the team.

## Real-Time Sync

Map the current `AppController` methods to Firestore listeners:

- `users` stream
- `invites` stream
- `shifts` stream
- `timeEntries` stream

That will keep updates synced across devices automatically.
