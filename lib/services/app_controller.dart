import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/models.dart';

class AppController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, AppUser> _users = {};
  final Map<String, Team> _teams = {};
  final Map<String, TeamInvite> _invites = {};
  final Map<String, WorkShift> _shifts = {};
  final Map<String, TimeEntry> _timeEntries = {};

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _teamSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _teamUsersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invitesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _shiftsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _timeEntriesSubscription;

  String? _currentUserId;
  bool _profileVerified = false;
  bool _isBusy = false;

  AppController() {
    _listenToAuth();
  }

  AppUser? get currentUser =>
      _currentUserId == null ? null : _users[_currentUserId];
  bool get isAuthenticated => currentUser != null;
  bool get isProfileVerified => _profileVerified;
  bool get isBusy => _isBusy;
  bool get hasFirebaseSession => _auth.currentUser != null;
  bool get hasActiveTeam => currentUser?.teamId != null;
  bool get needsProfileSetup =>
      hasFirebaseSession && currentUser == null && pendingInviteId != null;
  String? get authenticatedEmail => _auth.currentUser?.email;
  Team? get currentTeam =>
      currentUser?.teamId == null ? null : _teams[currentUser!.teamId];
  List<StateTaxProfile> get states => usStates;
  List<Team> get allTeams =>
      _teams.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  bool get hasPendingEmailLinkSignIn =>
      _auth.isSignInWithEmailLink(Uri.base.toString());
  String? get pendingInviteId => Uri.base.queryParameters['inviteId'];

  List<AppUser> get teamUsers {
    final teamId = currentUser?.teamId;
    if (teamId == null) {
      return const [];
    }

    return _users.values.where((user) => user.teamId == teamId).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<AppUser> membersForTeam(String teamId) {
    return _users.values.where((user) => user.teamId == teamId).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<TeamInvite> get currentTeamInvites {
    final teamId = currentUser?.teamId;
    if (teamId == null) {
      return const [];
    }

    return _invites.values.where((invite) => invite.teamId == teamId).toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  List<WorkShift> get currentTeamShifts {
    final teamId = currentUser?.teamId;
    if (teamId == null) {
      return const [];
    }

    return _shifts.values.where((shift) => shift.teamId == teamId).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<WorkShift> shiftsForUser(String userId) {
    return currentTeamShifts
        .where((shift) => shift.assignedUserId == userId)
        .toList();
  }

  TeamInvite? pendingInviteForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final invite in _invites.values) {
      if (invite.email.toLowerCase() == normalized &&
          invite.status == InviteStatus.pending) {
        return invite;
      }
    }
    return null;
  }

  Future<TeamInvite?> inviteById(String inviteId) async {
    final snapshot = await _firestore.collection('invites').doc(inviteId).get();
    if (!snapshot.exists) {
      return null;
    }
    return _inviteFromDoc(snapshot);
  }

  StateTaxProfile taxProfileFor(String stateCode) {
    return usStates.firstWhere(
      (state) => state.code == stateCode,
      orElse: () => usStates.first,
    );
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      _setBusy(true);
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _profileVerified = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Unable to sign in.';
    } on FirebaseException catch (error) {
      return error.message ?? 'Unable to sign in.';
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String username,
    required String stateCode,
    required UserRole requestedRole,
    required String businessName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();

    if (normalizedUsername.isEmpty) {
      return 'Username is required.';
    }

    if (requestedRole == UserRole.employee) {
      return 'Employees join through the invite email link, not the business account form.';
    }

    if (requestedRole == UserRole.manager && businessName.trim().isEmpty) {
      return 'Business accounts need a business name.';
    }

    UserCredential? credential;
    try {
      _setBusy(true);
      credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user!.uid;
      final teamRef = _firestore.collection('teams').doc();
      await teamRef.set({
        'name': businessName.trim(),
        'ownerUserId': uid,
        'managerIds': [uid],
        'memberIds': [uid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName.trim(),
        'email': normalizedEmail,
        'username': username.trim(),
        'usernameLower': normalizedUsername,
        'stateCode': stateCode,
        'role': 'manager',
        'teamId': teamRef.id,
        'hourlyRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _profileVerified = false;
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Unable to create account.';
    } on FirebaseException catch (error) {
      if (credential?.user != null) {
        await credential!.user!.delete();
      }
      return error.message ?? 'Unable to create account.';
    } finally {
      _setBusy(false);
    }
  }

  bool verifyUsername(String username) {
    if (currentUser == null ||
        currentUser!.username.toLowerCase() != username.trim().toLowerCase()) {
      return false;
    }

    _profileVerified = true;
    notifyListeners();
    return true;
  }

  String? signInWithWorkplaceUsername({
    required String teamId,
    required String userId,
    required String username,
  }) {
    final user = _users[userId];
    if (user == null || user.teamId != teamId) {
      return 'That account is no longer part of this workplace.';
    }

    if (user.username.toLowerCase() != username.trim().toLowerCase()) {
      return 'Username does not match the selected profile.';
    }

    _currentUserId = userId;
    _profileVerified = true;
    notifyListeners();
    return null;
  }

  Future<String?> completeEmailLinkSignIn({
    required String email,
  }) async {
    try {
      _setBusy(true);
      await _auth.signInWithEmailLink(
        email: email.trim(),
        emailLink: Uri.base.toString(),
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Unable to complete email-link sign in.';
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> completeInvitedRegistration({
    required String fullName,
    required String username,
    required String stateCode,
  }) async {
    final authUser = _auth.currentUser;
    final inviteId = pendingInviteId;
    if (authUser == null || inviteId == null || inviteId.isEmpty) {
      return 'Open the invite link first to finish joining the team.';
    }

    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      return 'Username is required.';
    }

    final usernameTaken = await _firestore
        .collection('users')
        .where('usernameLower', isEqualTo: normalizedUsername)
        .limit(1)
        .get();
    if (usernameTaken.docs.any((doc) => doc.id != authUser.uid)) {
      return 'That username is already taken.';
    }

    final invite = await inviteById(inviteId);
    if (invite == null) {
      return 'Invite not found.';
    }
    if (invite.status != InviteStatus.pending) {
      return 'This invite is no longer pending.';
    }
    if (invite.email.toLowerCase() != (authUser.email ?? '').toLowerCase()) {
      return 'This invite belongs to a different email address.';
    }

    try {
      _setBusy(true);
      await _firestore.collection('users').doc(authUser.uid).set({
        'fullName': fullName.trim(),
        'email': (authUser.email ?? '').trim().toLowerCase(),
        'username': username.trim(),
        'usernameLower': normalizedUsername,
        'stateCode': stateCode,
        'role': invite.role.name,
        'teamId': invite.teamId,
        'hourlyRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('invites').doc(inviteId).set({
        'status': 'accepted',
        'acceptedByUserId': authUser.uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _profileVerified = false;
      notifyListeners();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> logout() async {
    await _auth.signOut();
    _profileVerified = false;
    _currentUserId = null;
    notifyListeners();
    return null;
  }

  Future<void> updateProfile({
    required String fullName,
    required String stateCode,
    required String username,
  }) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection('users').doc(user.id).set({
      'fullName': fullName.trim(),
      'stateCode': stateCode,
      'username': username.trim(),
      'usernameLower': username.trim().toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateTeamName(String name) async {
    final team = currentTeam;
    if (team == null) {
      return;
    }

    await _firestore.collection('teams').doc(team.id).set({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> sendInvite({
    required String email,
    required UserRole role,
  }) async {
    final team = currentTeam;
    final authUser = _auth.currentUser;
    if (team == null || authUser == null) {
      return 'You must be signed in as a business manager first.';
    }

    try {
      _setBusy(true);
      final inviteRef = _firestore.collection('invites').doc();
      final linkUrl = '${Uri.base.origin}/?inviteId=${inviteRef.id}';

      await inviteRef.set({
        'teamId': team.id,
        'teamName': team.name,
        'email': email.trim().toLowerCase(),
        'role': role.name,
        'status': 'pending',
        'invitedByUserId': authUser.uid,
        'acceptedByUserId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
      });

      final settings = ActionCodeSettings(
        url: linkUrl,
        handleCodeInApp: true,
        androidPackageName: 'com.shiftsync.shiftsync',
        androidInstallApp: true,
        iOSBundleId: 'com.shiftsync.shiftsync',
      );

      await _auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: settings,
      );

      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Unable to send invite email.';
    } catch (error) {
      return 'Unexpected error sending invite: $error';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> revokeInvite(String inviteId) async {
    await _firestore.collection('invites').doc(inviteId).set({
      'status': 'revoked',
    }, SetOptions(merge: true));
  }

  TimeEntry? openEntryForUser(String userId) {
    for (final entry in _timeEntries.values) {
      if (entry.userId == userId && entry.isOpen) {
        return entry;
      }
    }
    return null;
  }

  Future<void> clockIn() async {
    final user = currentUser;
    if (user == null || user.teamId == null || openEntryForUser(user.id) != null) {
      return;
    }

    await _firestore.collection('timeEntries').add({
      'teamId': user.teamId,
      'userId': user.id,
      'clockIn': Timestamp.fromDate(DateTime.now()),
      'clockOut': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clockOut() async {
    final user = currentUser;
    final openEntry = user == null ? null : openEntryForUser(user.id);
    if (openEntry == null) {
      return;
    }

    await _firestore.collection('timeEntries').doc(openEntry.id).set({
      'clockOut': Timestamp.fromDate(DateTime.now()),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  double workedHoursForWeek(String userId, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    var total = 0.0;
    for (final entry in _timeEntries.values) {
      if (entry.userId == userId &&
          !entry.clockIn.isBefore(weekStart) &&
          entry.clockIn.isBefore(weekEnd)) {
        total += entry.hoursWorked;
      }
    }
    return total;
  }

  double scheduledHoursForPeriod(
      String userId, DateTime periodStart, DateTime periodEnd) {
    var total = 0.0;
    for (final shift in shiftsForUser(userId)) {
      if (shift.start.isBefore(periodEnd) && shift.end.isAfter(periodStart)) {
        total += shift.hours;
      }
    }
    return total;
  }

  PaycheckPreview paycheckForUser(String userId) {
    final user = _users[userId]!;
    final periodStart = _periodStart(DateTime.now());
    final periodEnd = periodStart.add(const Duration(days: 14));
    final scheduledHours =
        scheduledHoursForPeriod(userId, periodStart, periodEnd);
    final regularHours = scheduledHours > 80 ? 80.0 : scheduledHours;
    final overtimeHours = scheduledHours > 80 ? scheduledHours - 80 : 0.0;
    final grossPay = (regularHours * user.hourlyRate) +
        (overtimeHours * user.hourlyRate * 1.5);
    final federalWithholding = grossPay * 0.12;
    final ficaWithholding = grossPay * 0.0765;
    final stateWithholding =
        grossPay * taxProfileFor(user.stateCode).withholdingRate;
    final netPay =
        grossPay - federalWithholding - ficaWithholding - stateWithholding;

    return PaycheckPreview(
      regularHours: regularHours,
      overtimeHours: overtimeHours,
      grossPay: grossPay,
      federalWithholding: federalWithholding,
      stateWithholding: stateWithholding,
      ficaWithholding: ficaWithholding,
      netPay: netPay,
    );
  }

  DateTime payPeriodStart() => _periodStart(DateTime.now());

  Future<void> createShift({
    required String userId,
    required String roleName,
    required DateTime start,
    required DateTime end,
  }) async {
    final team = currentTeam;
    if (team == null) {
      return;
    }

    await _firestore.collection('shifts').add({
      'teamId': team.id,
      'roleName': roleName.trim(),
      'assignedUserId': userId,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'status': 'scheduled',
      'requestedByUserId': null,
      'pickupCandidateUserId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateShift({
    required String shiftId,
    required String userId,
    required String roleName,
    required DateTime start,
    required DateTime end,
  }) async {
    await _firestore.collection('shifts').doc(shiftId).set({
      'assignedUserId': userId,
      'roleName': roleName.trim(),
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'status': 'scheduled',
      'requestedByUserId': null,
      'pickupCandidateUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> duplicateShift(String shiftId) async {
    final shift = _shifts[shiftId];
    if (shift == null) {
      return;
    }

    await createShift(
      userId: shift.assignedUserId,
      roleName: shift.roleName,
      start: shift.start.add(const Duration(days: 7)),
      end: shift.end.add(const Duration(days: 7)),
    );
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    final user = _users[userId];
    if (user == null) {
      return;
    }

    await _firestore.collection('users').doc(userId).set({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (user.teamId != null) {
      await _firestore.collection('teams').doc(user.teamId).set({
        if (role == UserRole.manager)
          'managerIds': FieldValue.arrayUnion([userId])
        else
          'managerIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateHourlyRate(String userId, double hourlyRate) async {
    await _firestore.collection('users').doc(userId).set({
      'hourlyRate': hourlyRate,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeEmployee(String userId) async {
    final team = currentTeam;
    final employee = _users[userId];
    if (team == null || employee == null || employee.teamId != team.id) {
      return;
    }

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final teamRef = _firestore.collection('teams').doc(team.id);

    batch.set(userRef, {
      'teamId': null,
      'role': 'employee',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(teamRef, {
      'memberIds': FieldValue.arrayRemove([userId]),
      'managerIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final assignedShifts = await _firestore
        .collection('shifts')
        .where('teamId', isEqualTo: team.id)
        .where('assignedUserId', isEqualTo: userId)
        .get();

    final now = DateTime.now();
    for (final shiftDoc in assignedShifts.docs) {
      final shift = _shiftFromDoc(shiftDoc);
      if (shift.end.isAfter(now)) {
        batch.set(shiftDoc.reference, {
          'status': 'open',
          'requestedByUserId': null,
          'pickupCandidateUserId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  Future<void> requestShiftDrop(String shiftId) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection('shifts').doc(shiftId).set({
      'status': 'dropRequested',
      'requestedByUserId': user.id,
      'pickupCandidateUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveShiftDrop(String shiftId) async {
    await _firestore.collection('shifts').doc(shiftId).set({
      'status': 'open',
      'pickupCandidateUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> claimOpenShift(String shiftId) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection('shifts').doc(shiftId).set({
      'status': 'pickupPending',
      'pickupCandidateUserId': user.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> approveShiftPickup(String shiftId) async {
    final shift = _shifts[shiftId];
    if (shift == null || shift.pickupCandidateUserId == null) {
      return;
    }

    await _firestore.collection('shifts').doc(shiftId).set({
      'assignedUserId': shift.pickupCandidateUserId,
      'status': 'scheduled',
      'requestedByUserId': null,
      'pickupCandidateUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String employeeName(String userId) =>
      _users[userId]?.fullName ?? 'Unknown employee';

  AppUser? userById(String userId) => _users[userId];

  DateTime startOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));

  void _listenToAuth() {
    _authSubscription = _auth.authStateChanges().listen((authUser) {
      _currentUserId = authUser?.uid;
      _profileVerified = false;
      _userSubscription?.cancel();

      if (authUser == null) {
        _users.clear();
        _teams.clear();
        _invites.clear();
        _shifts.clear();
        _timeEntries.clear();
        _teamSubscription?.cancel();
        _teamUsersSubscription?.cancel();
        _invitesSubscription?.cancel();
        _shiftsSubscription?.cancel();
        _timeEntriesSubscription?.cancel();
        notifyListeners();
        return;
      }

      _userSubscription = _firestore
          .collection('users')
          .doc(authUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final user = _userFromDoc(snapshot);
          _users[user.id] = user;
          _listenToTeamScopedData(user.teamId, user.role, user.id);
        }
        notifyListeners();
      });
    });
  }

  void _listenToTeamScopedData(String? teamId, UserRole role, String userId) {
    _teamSubscription?.cancel();
    _teamUsersSubscription?.cancel();
    _invitesSubscription?.cancel();
    _shiftsSubscription?.cancel();
    _timeEntriesSubscription?.cancel();
    _invites.clear();

    if (teamId == null) {
      _teams.clear();
      _shifts.clear();
      _timeEntries.clear();
      return;
    }

    _teamSubscription = _firestore.collection('teams').doc(teamId).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final team = _teamFromDoc(snapshot);
        _teams[team.id] = team;
      }
      notifyListeners();
    });

    if (role == UserRole.manager) {
      _teamUsersSubscription = _firestore
          .collection('users')
          .where('teamId', isEqualTo: teamId)
          .snapshots()
          .listen((snapshot) {
        for (final doc in snapshot.docs) {
          final user = _userFromDoc(doc);
          _users[user.id] = user;
        }
        notifyListeners();
      });

      _invitesSubscription = _firestore
          .collection('invites')
          .where('teamId', isEqualTo: teamId)
          .snapshots()
          .listen((snapshot) {
        _invites
          ..removeWhere((_, invite) => invite.teamId == teamId)
          ..addEntries(snapshot.docs.map((doc) {
            final invite = _inviteFromDoc(doc);
            return MapEntry(invite.id, invite);
          }));
        notifyListeners();
      });
    }

    _shiftsSubscription = _firestore
        .collection('shifts')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen((snapshot) {
      _shifts
        ..removeWhere((_, shift) => shift.teamId == teamId)
        ..addEntries(snapshot.docs.map((doc) {
          final shift = _shiftFromDoc(doc);
          return MapEntry(shift.id, shift);
        }));
      notifyListeners();
    });

    _timeEntriesSubscription = _firestore
        .collection('timeEntries')
        .where(role == UserRole.manager ? 'teamId' : 'userId', isEqualTo: role == UserRole.manager ? teamId : userId)
        .snapshots()
        .listen((snapshot) {
      _timeEntries
        ..clear()
        ..addEntries(snapshot.docs.map((doc) {
        final entry = _timeEntryFromDoc(doc);
        return MapEntry(entry.id, entry);
      }));
      notifyListeners();
    });
  }

  AppUser _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      fullName: (data['fullName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      password: '',
      username: (data['username'] ?? '') as String,
      stateCode: (data['stateCode'] ?? 'IL') as String,
      role: _roleFromString((data['role'] ?? 'employee') as String),
      hourlyRate: ((data['hourlyRate'] ?? 0) as num).toDouble(),
      teamId: data['teamId'] as String?,
    );
  }

  Team _teamFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Team(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      managerIds: List<String>.from(data['managerIds'] ?? const []),
      memberIds: List<String>.from(data['memberIds'] ?? const []),
    );
  }

  TeamInvite _inviteFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TeamInvite(
      id: doc.id,
      teamId: (data['teamId'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      role: _roleFromString((data['role'] ?? 'employee') as String),
      invitedByUserId: (data['invitedByUserId'] ?? '') as String,
      sentAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _inviteStatusFromString((data['status'] ?? 'pending') as String),
    );
  }

  WorkShift _shiftFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return WorkShift(
      id: doc.id,
      teamId: data['teamId'] as String,
      roleName: data['roleName'] as String,
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
      assignedUserId: data['assignedUserId'] as String,
      status: _shiftStatusFromString((data['status'] ?? 'scheduled') as String),
      requestedByUserId: data['requestedByUserId'] as String?,
      pickupCandidateUserId: data['pickupCandidateUserId'] as String?,
    );
  }

  TimeEntry _timeEntryFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TimeEntry(
      id: doc.id,
      userId: data['userId'] as String,
      clockIn: (data['clockIn'] as Timestamp).toDate(),
      clockOut: (data['clockOut'] as Timestamp?)?.toDate(),
    );
  }

  UserRole _roleFromString(String value) {
    return value == 'manager' ? UserRole.manager : UserRole.employee;
  }

  InviteStatus _inviteStatusFromString(String value) {
    return switch (value) {
      'accepted' => InviteStatus.accepted,
      'revoked' => InviteStatus.revoked,
      _ => InviteStatus.pending,
    };
  }

  ShiftStatus _shiftStatusFromString(String value) {
    return switch (value) {
      'dropRequested' => ShiftStatus.dropRequested,
      'open' => ShiftStatus.open,
      'pickupPending' => ShiftStatus.pickupPending,
      _ => ShiftStatus.scheduled,
    };
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  DateTime _periodStart(DateTime date) {
    final weekStart = startOfWeek(date);
    final anchor = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final isEvenWeek =
        anchor.difference(DateTime(2026, 1, 5)).inDays ~/ 7 % 2 == 0;
    return isEvenWeek ? anchor : anchor.subtract(const Duration(days: 7));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    _teamSubscription?.cancel();
    _teamUsersSubscription?.cancel();
    _invitesSubscription?.cancel();
    _shiftsSubscription?.cancel();
    _timeEntriesSubscription?.cancel();
    super.dispose();
  }
}
