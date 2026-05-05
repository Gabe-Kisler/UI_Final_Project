const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');

admin.initializeApp();

const db = admin.firestore();

function assertSignedIn(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
}

async function getUser(uid) {
  const snapshot = await db.collection('users').doc(uid).get();
  if (!snapshot.exists) {
    throw new HttpsError('not-found', 'User profile not found.');
  }
  return snapshot.data();
}

exports.setSecurePin = onCall(async (request) => {
  assertSignedIn(request);

  const pin = `${request.data?.pin ?? ''}`;
  if (!/^\d{4}$/.test(pin)) {
    throw new HttpsError('invalid-argument', 'PIN must be exactly 4 digits.');
  }

  const pinHash = await bcrypt.hash(pin, 12);
  await db.collection('users').doc(request.auth.uid).set(
    {
      pinHash,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { success: true };
});

exports.verifySecurePin = onCall(async (request) => {
  assertSignedIn(request);

  const pin = `${request.data?.pin ?? ''}`;
  if (!/^\d{4}$/.test(pin)) {
    throw new HttpsError('invalid-argument', 'PIN must be exactly 4 digits.');
  }

  const user = await getUser(request.auth.uid);
  if (!user.pinHash) {
    throw new HttpsError('failed-precondition', 'No PIN has been set for this account.');
  }

  const valid = await bcrypt.compare(pin, user.pinHash);
  return { valid };
});

exports.createTeamInvite = onCall(async (request) => {
  assertSignedIn(request);

  const inviterUid = request.auth.uid;
  const inviter = await getUser(inviterUid);
  if (inviter.role !== 'manager') {
    throw new HttpsError('permission-denied', 'Only managers can invite employees.');
  }

  const email = `${request.data?.email ?? ''}`.trim().toLowerCase();
  const role = `${request.data?.role ?? 'employee'}`;
  const teamId = `${request.data?.teamId ?? inviter.teamId ?? ''}`;
  const teamName = `${request.data?.teamName ?? ''}`.trim();
  const appBaseUrl = `${request.data?.appBaseUrl ?? ''}`.trim();

  if (!email) {
    throw new HttpsError('invalid-argument', 'Employee email is required.');
  }
  if (!teamId) {
    throw new HttpsError('invalid-argument', 'Team id is required.');
  }
  if (!teamName) {
    throw new HttpsError('invalid-argument', 'Team name is required.');
  }
  if (!appBaseUrl) {
    throw new HttpsError('invalid-argument', 'App base URL is required.');
  }

  const inviteRef = db.collection('invites').doc();
  const joinUrl = `${appBaseUrl.replace(/\/$/, '')}/join?inviteId=${inviteRef.id}`;

  await inviteRef.set({
    teamId,
    teamName,
    email,
    role,
    status: 'pending',
    invitedByUserId: inviterUid,
    acceptedByUserId: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    acceptedAt: null,
  });

  await db.collection('mail').add({
    to: email,
    message: {
      subject: `You're invited to join ${teamName} on ShiftSync`,
      html: `
        <p>You were invited to join <strong>${teamName}</strong> on ShiftSync.</p>
        <p>Create your account with this email address, then join using the link below:</p>
        <p><a href="${joinUrl}">${joinUrl}</a></p>
        <p>If you already have an account with this email, sign in and complete the join flow.</p>
      `,
    },
  });

  return { inviteId: inviteRef.id, joinUrl };
});

exports.acceptTeamInvite = onCall(async (request) => {
  assertSignedIn(request);

  const inviteId = `${request.data?.inviteId ?? ''}`.trim();
  if (!inviteId) {
    throw new HttpsError('invalid-argument', 'Invite id is required.');
  }

  const inviteRef = db.collection('invites').doc(inviteId);
  const inviteSnap = await inviteRef.get();
  if (!inviteSnap.exists) {
    throw new HttpsError('not-found', 'Invite not found.');
  }

  const invite = inviteSnap.data();
  const authUser = await admin.auth().getUser(request.auth.uid);
  const authEmail = (authUser.email || '').toLowerCase();

  if (invite.status !== 'pending') {
    throw new HttpsError('failed-precondition', 'Invite is no longer pending.');
  }
  if (invite.email !== authEmail) {
    throw new HttpsError('permission-denied', 'Invite email does not match signed-in user.');
  }

  const teamRef = db.collection('teams').doc(invite.teamId);
  const teamSnap = await teamRef.get();
  if (!teamSnap.exists) {
    throw new HttpsError('not-found', 'Team not found.');
  }

  const team = teamSnap.data();
  const memberIds = Array.isArray(team.memberIds) ? team.memberIds : [];
  const managerIds = Array.isArray(team.managerIds) ? team.managerIds : [];

  const nextMemberIds = memberIds.includes(request.auth.uid)
    ? memberIds
    : [...memberIds, request.auth.uid];
  const nextManagerIds =
    invite.role === 'manager' && !managerIds.includes(request.auth.uid)
      ? [...managerIds, request.auth.uid]
      : managerIds;

  await db.collection('users').doc(request.auth.uid).set(
    {
      email: authEmail,
      role: invite.role,
      teamId: invite.teamId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await teamRef.set(
    {
      memberIds: nextMemberIds,
      managerIds: nextManagerIds,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await inviteRef.set(
    {
      status: 'accepted',
      acceptedByUserId: request.auth.uid,
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { success: true, teamId: invite.teamId, role: invite.role };
});
