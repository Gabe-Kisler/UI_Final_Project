import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/mock_data.dart';

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
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final shifts = mockShifts.where((s) => s.employeeId == 'e1').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'My Schedule',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _weekNavButton(Icons.chevron_left, () {
                    setState(() => _weekStart =
                        _weekStart.subtract(const Duration(days: 7)));
                  }),
                  Text(
                    _weekLabel(),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  _weekNavButton(Icons.chevron_right, () {
                    setState(() =>
                        _weekStart = _weekStart.add(const Duration(days: 7)));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildDayStrip(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final day = _weekStart.add(Duration(days: i));
                  final dayShifts = shifts
                      .where((s) =>
                          s.start.year == day.year &&
                          s.start.month == day.month &&
                          s.start.day == day.day)
                      .toList();
                  return _DayCard(day: day, shifts: dayShifts);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekNavButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: AppColors.textSecondary, size: 20),
      onPressed: onTap,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
    );
  }

  String _weekLabel() {
    final fmt = DateFormat('MMM d');
    return '${fmt.format(_weekStart)}–${fmt.format(_weekStart.add(const Duration(days: 6)))}';
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
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          return _DayChip(label: labels[i], number: day.day, isToday: isToday);
        }),
      ),
    );
  }
}

// ── Day strip chip ────────────────────────────────────────────────────────────

class _DayChip extends StatelessWidget {
  final String label;
  final int number;
  final bool isToday;
  const _DayChip(
      {required this.label, required this.number, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: isToday ? Colors.white70 : AppColors.textMuted,
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text('$number',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Tappable day card ─────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final DateTime day;
  final List<Shift> shifts;
  const _DayCard({required this.day, required this.shifts});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DayDetailSheet(day: day, shifts: shifts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, MMM d');
    final timeFmt = DateFormat('h:mm a');
    final hasShifts = shifts.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt.format(day),
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    if (!hasShifts)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Day off',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      )
                    else
                      ...shifts.map((s) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.role,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      Text(
                                        '${timeFmt.format(s.start)} – ${timeFmt.format(s.end)}',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${s.hours.toStringAsFixed(0)}h',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: hasShifts ? AppColors.primary : AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day detail bottom sheet ───────────────────────────────────────────────────

class _DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final List<Shift> shifts;
  const _DayDetailSheet({required this.day, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, MMMM d');
    final timeFmt = DateFormat('h:mm a');
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

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
          // Day header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmt.format(day),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: shifts.isEmpty
                      ? AppColors.surfaceVariant
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  shifts.isEmpty
                      ? 'Day Off'
                      : '${shifts.length} shift${shifts.length > 1 ? 's' : ''}',
                  style: TextStyle(
                      color:
                          shifts.isEmpty ? AppColors.textMuted : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Content
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
                  Icon(Icons.event_available_outlined,
                      color: AppColors.textMuted, size: 36),
                  const SizedBox(height: 10),
                  Text('No shifts scheduled',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Enjoy your day off!',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            )
          else
            ...shifts.map((s) {
              final totalMins = s.end.difference(s.start).inMinutes;
              final hrs = totalMins ~/ 60;
              final mins = totalMins % 60;
              final durationLabel =
                  mins == 0 ? '${hrs}h' : '${hrs}h ${mins}m';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.cardBorder, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.role,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            '${timeFmt.format(s.start)} – ${timeFmt.format(s.end)}',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(durationLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                        Text('duration',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
