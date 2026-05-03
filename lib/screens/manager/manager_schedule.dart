import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/mock_data.dart';

class ManagerSchedule extends StatefulWidget {
  const ManagerSchedule({super.key});

  @override
  State<ManagerSchedule> createState() => _ManagerScheduleState();
}

class _ManagerScheduleState extends State<ManagerSchedule> {
  late DateTime _weekStart;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDayTapped(DateTime day) {
    final allShifts = mockShifts
        .where((s) => _isSameDay(s.start, day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DayShiftsSheet(
        day: day,
        shifts: allShifts,
        employees: mockEmployees,
      ),
    );

    setState(() => _selectedDay = day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Text('Schedule',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Shift',
                        style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildWeekNav(),
            const SizedBox(height: 8),
            _buildDayStrip(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockEmployees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final emp = mockEmployees[i];
                  final empShifts = mockShifts
                      .where((s) => s.employeeId == emp.id)
                      .toList();
                  return _EmployeeRow(
                      employee: emp,
                      shifts: empShifts,
                      weekStart: _weekStart);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNav() {
    final fmt = DateFormat('MMM d');
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                color: AppColors.textSecondary),
            onPressed: () => setState(() {
              _weekStart =
                  _weekStart.subtract(const Duration(days: 7));
              _selectedDay = null;
            }),
          ),
          Text(
            '${fmt.format(_weekStart)} – ${fmt.format(weekEnd)}',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
            onPressed: () => setState(() {
              _weekStart = _weekStart.add(const Duration(days: 7));
              _selectedDay = null;
            }),
          ),
          const Spacer(),
          Text(
            '${mockShifts.length} shifts scheduled',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final isToday = _isSameDay(day, today);
          final isSelected =
              _selectedDay != null && _isSameDay(day, _selectedDay!);
          final shiftsOnDay =
              mockShifts.where((s) => _isSameDay(s.start, day)).length;

          return GestureDetector(
            onTap: () => _onDayTapped(day),
            child: Container(
              width: 42,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 1)
                    : null,
              ),
              child: Column(
                children: [
                  Text(labels[i],
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textMuted,
                          fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('${day.day}',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  // shift count dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      shiftsOnDay.clamp(0, 3),
                      (_) => Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white70
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Day shifts bottom sheet ───────────────────────────────────────────────────

class _DayShiftsSheet extends StatelessWidget {
  final DateTime day;
  final List<Shift> shifts;
  final List<Employee> employees;
  const _DayShiftsSheet(
      {required this.day,
      required this.shifts,
      required this.employees});

  Employee? _employee(String id) =>
      employees.where((e) => e.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, MMMM d');
    final timeFmt = DateFormat('h:mm a');
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
    final totalHours =
        shifts.fold<double>(0, (sum, s) => sum + s.hours);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt.format(day),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Today',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              if (shifts.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${shifts.length} shift${shifts.length > 1 ? 's' : ''}',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text('${totalHours.toStringAsFixed(1)}h total',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Shift list
          if (shifts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy_outlined,
                      color: AppColors.textMuted, size: 36),
                  const SizedBox(height: 10),
                  Text('No shifts scheduled',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            )
          else
            ...shifts.map((s) {
              final emp = _employee(s.employeeId);
              final totalMins =
                  s.end.difference(s.start).inMinutes;
              final hrs = totalMins ~/ 60;
              final mins = totalMins % 60;
              final durationLabel =
                  mins == 0 ? '${hrs}h' : '${hrs}h ${mins}m';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.cardBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    // Employee avatar
                    if (emp != null)
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(emp.initials,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp?.name ?? 'Unknown',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(s.role,
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${timeFmt.format(s.start)} – ${timeFmt.format(s.end)}',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(durationLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Employee week row ─────────────────────────────────────────────────────────

class _EmployeeRow extends StatelessWidget {
  final Employee employee;
  final List<Shift> shifts;
  final DateTime weekStart;
  const _EmployeeRow(
      {required this.employee,
      required this.shifts,
      required this.weekStart});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('E h:mm a');
    final endFmt = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(employee: employee),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(employee.role,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${employee.hoursThisWeek}h',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  if (employee.isClockedIn)
                    Text('Clocked in',
                        style: TextStyle(
                            color: AppColors.success, fontSize: 11)),
                ],
              ),
            ],
          ),
          if (shifts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shifts
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3),
                              width: 0.5),
                        ),
                        child: Text(
                          '${timeFmt.format(s.start)}–${endFmt.format(s.end)}  ·  ${s.role}',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 11),
                        ),
                      ))
                  .toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No shifts this week',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Employee employee;
  const _Avatar({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(employee.initials,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ),
        if (employee.isClockedIn)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
