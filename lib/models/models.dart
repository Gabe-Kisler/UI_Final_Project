class Shift {
  final String id;
  final String role;
  final DateTime start;
  final DateTime end;
  final String employeeId;

  const Shift({
    required this.id,
    required this.role,
    required this.start,
    required this.end,
    required this.employeeId,
  });

  double get hours => end.difference(start).inMinutes / 60.0;
}

class Employee {
  final String id;
  final String name;
  final String role;
  final double hourlyRate;
  final bool isClockedIn;
  final double hoursThisWeek;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.hourlyRate,
    this.isClockedIn = false,
    this.hoursThisWeek = 0,
  });

  String get initials {
    final parts = name.split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }
}

class PayPeriod {
  final DateTime start;
  final DateTime end;
  final double expectedPay;
  final double pendingPay;

  const PayPeriod({
    required this.start,
    required this.end,
    required this.expectedPay,
    required this.pendingPay,
  });
}

enum AlertType { missedClockIn, overtime, swapRequest }

class ShiftAlert {
  final String message;
  final String subtitle;
  final AlertType type;

  const ShiftAlert({
    required this.message,
    required this.subtitle,
    required this.type,
  });
}

class ShiftGap {
  final String role;
  final String timeRange;
  final String reason;

  const ShiftGap({
    required this.role,
    required this.timeRange,
    required this.reason,
  });
}
