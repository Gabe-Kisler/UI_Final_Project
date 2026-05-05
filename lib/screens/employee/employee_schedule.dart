import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class EmployeeSchedule extends StatefulWidget {
  const EmployeeSchedule({super.key});

  @override
  State<EmployeeSchedule> createState() => _EmployeeScheduleState();
}

class _EmployeeScheduleState extends State<EmployeeSchedule> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _weekStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final user = controller.currentUser!;
    final shifts = controller.shiftsForUser(user.id)
      ..sort((a, b) => a.start.compareTo(b.start));
    final openShifts = controller.currentTeamShifts
        .where((shift) =>
            shift.status == ShiftStatus.open && shift.assignedUserId != user.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('My Schedule',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _weekStart =
                        _weekStart.subtract(const Duration(days: 7))),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  Text(
                    '${DateFormat('MMM d').format(_weekStart)} - ${DateFormat('MMM d').format(_weekStart.add(const Duration(days: 6)))}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  IconButton(
                    onPressed: () => setState(() =>
                        _weekStart = _weekStart.add(const Duration(days: 7))),
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    ...List.generate(7, (index) {
                      final day = _weekStart.add(Duration(days: index));
                      final dayShifts = shifts
                          .where((shift) => _isSameDay(shift.start, day))
                          .toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EmployeeDayCard(
                          day: day,
                          shifts: dayShifts,
                          onDrop: controller.requestShiftDrop,
                        ),
                      );
                    }),
                    if (openShifts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Available to Pick Up',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...openShifts.map(
                        (shift) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(shift.roleName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${DateFormat('EEE, MMM d').format(shift.start)}  ${DateFormat('h:mm a').format(shift.start)} - ${DateFormat('h:mm a').format(shift.end)}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      controller.claimOpenShift(shift.id),
                                  child: const Text('Request pickup'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EmployeeDayCard extends StatelessWidget {
  final DateTime day;
  final List<WorkShift> shifts;
  final ValueChanged<String> onDrop;

  const _EmployeeDayCard({
    required this.day,
    required this.shifts,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('EEEE, MMMM d').format(day),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (shifts.isEmpty)
            const Text('Day off',
                style: TextStyle(color: AppColors.textSecondary))
          else
            ...shifts.map(
              (shift) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shift.roleName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('h:mm a').format(shift.start)} - ${DateFormat('h:mm a').format(shift.end)}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(_statusText(shift.status),
                                style: TextStyle(
                                    color: _statusColor(shift.status))),
                          ],
                        ),
                      ),
                      if (shift.status == ShiftStatus.scheduled)
                        OutlinedButton(
                          onPressed: () => onDrop(shift.id),
                          child: const Text('Drop shift'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusText(ShiftStatus status) {
    return switch (status) {
      ShiftStatus.scheduled => 'Scheduled',
      ShiftStatus.dropRequested => 'Drop request awaiting manager approval',
      ShiftStatus.open => 'Open for pickup',
      ShiftStatus.pickupPending => 'Pickup request awaiting approval',
    };
  }

  Color _statusColor(ShiftStatus status) {
    return switch (status) {
      ShiftStatus.scheduled => AppColors.accent,
      ShiftStatus.dropRequested => AppColors.warning,
      ShiftStatus.open => AppColors.primary,
      ShiftStatus.pickupPending => AppColors.warning,
    };
  }
}
