enum UserRole { manager, employee }

enum InviteStatus { pending, accepted, revoked }

enum ShiftStatus { scheduled, dropRequested, open, pickupPending }

class StateTaxProfile {
  final String code;
  final String name;
  final double withholdingRate;

  const StateTaxProfile({
    required this.code,
    required this.name,
    required this.withholdingRate,
  });
}

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final String username;
  final String stateCode;
  final UserRole role;
  final String? teamId;
  final double hourlyRate;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.username,
    required this.stateCode,
    required this.role,
    required this.hourlyRate,
    this.teamId,
  });

  AppUser copyWith({
    String? fullName,
    String? email,
    String? password,
    String? username,
    String? stateCode,
    UserRole? role,
    String? teamId,
    double? hourlyRate,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
      stateCode: stateCode ?? this.stateCode,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class Team {
  final String id;
  final String name;
  final List<String> managerIds;
  final List<String> memberIds;

  const Team({
    required this.id,
    required this.name,
    required this.managerIds,
    required this.memberIds,
  });

  Team copyWith({
    String? name,
    List<String>? managerIds,
    List<String>? memberIds,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      managerIds: managerIds ?? this.managerIds,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}

class TeamInvite {
  final String id;
  final String teamId;
  final String email;
  final UserRole role;
  final String invitedByUserId;
  final DateTime sentAt;
  final InviteStatus status;

  const TeamInvite({
    required this.id,
    required this.teamId,
    required this.email,
    required this.role,
    required this.invitedByUserId,
    required this.sentAt,
    this.status = InviteStatus.pending,
  });

  TeamInvite copyWith({
    InviteStatus? status,
    UserRole? role,
  }) {
    return TeamInvite(
      id: id,
      teamId: teamId,
      email: email,
      role: role ?? this.role,
      invitedByUserId: invitedByUserId,
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }
}

class WorkShift {
  final String id;
  final String teamId;
  final String roleName;
  final DateTime start;
  final DateTime end;
  final String assignedUserId;
  final ShiftStatus status;
  final String? requestedByUserId;
  final String? pickupCandidateUserId;

  const WorkShift({
    required this.id,
    required this.teamId,
    required this.roleName,
    required this.start,
    required this.end,
    required this.assignedUserId,
    this.status = ShiftStatus.scheduled,
    this.requestedByUserId,
    this.pickupCandidateUserId,
  });

  WorkShift copyWith({
    String? roleName,
    DateTime? start,
    DateTime? end,
    String? assignedUserId,
    ShiftStatus? status,
    String? requestedByUserId,
    String? pickupCandidateUserId,
  }) {
    return WorkShift(
      id: id,
      teamId: teamId,
      roleName: roleName ?? this.roleName,
      start: start ?? this.start,
      end: end ?? this.end,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      status: status ?? this.status,
      requestedByUserId: requestedByUserId,
      pickupCandidateUserId: pickupCandidateUserId,
    );
  }

  double get hours => end.difference(start).inMinutes / 60.0;
}

class TimeEntry {
  final String id;
  final String userId;
  final DateTime clockIn;
  final DateTime? clockOut;

  const TimeEntry({
    required this.id,
    required this.userId,
    required this.clockIn,
    this.clockOut,
  });

  TimeEntry copyWith({
    DateTime? clockOut,
  }) {
    return TimeEntry(
      id: id,
      userId: userId,
      clockIn: clockIn,
      clockOut: clockOut ?? this.clockOut,
    );
  }

  bool get isOpen => clockOut == null;

  double get hoursWorked {
    final end = clockOut ?? DateTime.now();
    return end.difference(clockIn).inMinutes / 60.0;
  }
}

class PaycheckPreview {
  final double regularHours;
  final double overtimeHours;
  final double grossPay;
  final double federalWithholding;
  final double stateWithholding;
  final double ficaWithholding;
  final double netPay;

  const PaycheckPreview({
    required this.regularHours,
    required this.overtimeHours,
    required this.grossPay,
    required this.federalWithholding,
    required this.stateWithholding,
    required this.ficaWithholding,
    required this.netPay,
  });
}
