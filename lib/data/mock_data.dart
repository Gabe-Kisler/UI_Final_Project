import '../models/models.dart';

final List<Employee> mockEmployees = [
  Employee(
    id: 'e1',
    name: 'Eli Smith',
    role: 'Cashier',
    hourlyRate: 21.20,
    isClockedIn: false,
    hoursThisWeek: 38.5,
  ),
  Employee(
    id: 'e2',
    name: 'George H',
    role: 'Cashier',
    hourlyRate: 18.50,
    isClockedIn: false,
    hoursThisWeek: 32.0,
  ),
  Employee(
    id: 'e3',
    name: 'Kim L',
    role: 'Warehouse',
    hourlyRate: 22.00,
    isClockedIn: true,
    hoursThisWeek: 41.5,
  ),
  Employee(
    id: 'e4',
    name: 'Jimmy T',
    role: 'Support',
    hourlyRate: 19.75,
    isClockedIn: true,
    hoursThisWeek: 35.0,
  ),
];

List<Shift> get mockShifts {
  final now = DateTime.now();
  return [
    Shift(
      id: 's1',
      role: 'Cashier',
      start: DateTime(now.year, now.month, now.day, 17, 0),
      end: DateTime(now.year, now.month, now.day, 22, 0),
      employeeId: 'e1',
    ),
    Shift(
      id: 's2',
      role: 'Warehouse',
      start: DateTime(now.year, now.month, now.day + 2, 15, 0),
      end: DateTime(now.year, now.month, now.day + 2, 22, 0),
      employeeId: 'e1',
    ),
    Shift(
      id: 's3',
      role: 'Cashier',
      start: DateTime(now.year, now.month, now.day + 3, 9, 0),
      end: DateTime(now.year, now.month, now.day + 3, 17, 0),
      employeeId: 'e1',
    ),
    Shift(
      id: 's4',
      role: 'Cashier',
      start: DateTime(now.year, now.month, now.day + 4, 17, 0),
      end: DateTime(now.year, now.month, now.day + 4, 22, 0),
      employeeId: 'e1',
    ),
    Shift(
      id: 's5',
      role: 'Cashier',
      start: DateTime(now.year, now.month, now.day, 9, 0),
      end: DateTime(now.year, now.month, now.day, 15, 0),
      employeeId: 'e2',
    ),
    Shift(
      id: 's6',
      role: 'Warehouse',
      start: DateTime(now.year, now.month, now.day, 8, 0),
      end: DateTime(now.year, now.month, now.day, 16, 0),
      employeeId: 'e3',
    ),
    Shift(
      id: 's7',
      role: 'Support',
      start: DateTime(now.year, now.month, now.day, 12, 0),
      end: DateTime(now.year, now.month, now.day, 20, 0),
      employeeId: 'e4',
    ),
  ];
}

final List<ShiftAlert> mockAlerts = [
  ShiftAlert(
    message: 'George H missed 4:00pm clock-in',
    subtitle: '8 minutes ago',
    type: AlertType.missedClockIn,
  ),
  ShiftAlert(
    message: 'Kim L crossed OT threshold',
    subtitle: '45 minutes ago',
    type: AlertType.overtime,
  ),
  ShiftAlert(
    message: 'Shift swap request — Gabe ↔ Jimmy',
    subtitle: '2h ago',
    type: AlertType.swapRequest,
  ),
];

final List<ShiftGap> mockShiftGaps = [
  ShiftGap(
    role: 'Cashier',
    timeRange: 'Tonight 4–10 PM',
    reason: 'George H no show — uncovered',
  ),
  ShiftGap(
    role: 'Warehouse',
    timeRange: 'Sat 8 AM – 2 PM',
    reason: 'Swap pending approval – 1 offer',
  ),
  ShiftGap(
    role: 'Support',
    timeRange: 'Sun 12–6 PM',
    reason: 'Understaffed',
  ),
];

PayPeriod get mockPayPeriod {
  final now = DateTime.now();
  return PayPeriod(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month, 15),
    expectedPay: 1468.88,
    pendingPay: 826.00,
  );
}

const List<double> weeklyLaborCost = [580, 620, 750, 490, 680, 710, 482];
