import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/mock_data.dart';
import '../role_select_screen.dart';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  bool _isClockedIn = false;

  void _toggleClock() => setState(() => _isClockedIn = !_isClockedIn);

  @override
  Widget build(BuildContext context) {
    final employee = mockEmployees.first;
    final shifts = mockShifts;
    final pay = mockPayPeriod;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(employee),
              const SizedBox(height: 16),
              _buildTimeClock(now),
              const SizedBox(height: 12),
              _buildStatsRow(employee, pay, shifts),
              const SizedBox(height: 12),
              _buildUpcomingShifts(shifts),
              const SizedBox(height: 12),
              _buildPayPeriod(pay),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Employee employee) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(
              employee.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'logout') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
                (_) => false,
              );
            }
          },
          color: AppColors.surfaceVariant,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  SizedBox(width: 10),
                  Text('Sign Out', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
          child: _Avatar(initials: employee.initials),
        ),
      ],
    );
  }

  Widget _buildTimeClock(DateTime now) {
    final timeStr = DateFormat('H:mm').format(now);
    final dateStr = DateFormat('EEE, MMM d').format(now);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Label('TIME CLOCK'),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isClockedIn ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isClockedIn ? 'Clocked in' : 'Not clocked in',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 54,
                fontWeight: FontWeight.bold,
                height: 1),
          ),
          Text(dateStr,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleClock,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isClockedIn ? AppColors.surfaceVariant : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                _isClockedIn ? 'Clock Out' : 'Clock In',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      Employee employee, PayPeriod pay, List<Shift> shifts) {
    final upcomingCount =
        shifts.where((s) => s.start.isAfter(DateTime.now())).length;
    return Row(
      children: [
        _StatChip(value: '${employee.hoursThisWeek}', label: 'Hrs\nthis week'),
        const SizedBox(width: 8),
        _StatChip(
            value: '\$${pay.pendingPay.toStringAsFixed(0)}',
            label: 'Pending\npay'),
        const SizedBox(width: 8),
        _StatChip(value: '4.3', label: 'Avg Hrs\nper day'),
        const SizedBox(width: 8),
        _StatChip(value: '$upcomingCount', label: 'Upcoming\nshifts'),
      ],
    );
  }

  Widget _buildUpcomingShifts(List<Shift> shifts) {
    final upcoming = shifts
        .where((s) => s.start.isAfter(DateTime.now()))
        .take(4)
        .toList();
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              _Label('UPCOMING SHIFTS'),
              const Spacer(),
              Text('view all',
                  style:
                      TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...upcoming.map((s) => _ShiftTile(shift: s)),
        ],
      ),
    );
  }

  Widget _buildPayPeriod(PayPeriod pay) {
    final fmt = DateFormat('MMM d');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Label('PAY PERIOD'),
              const Spacer(),
              Text(
                '${fmt.format(pay.start)} – ${fmt.format(pay.end)}',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Expected payout:',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            '\$${pay.expectedPay.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(value.length > 4 ? label : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.25)),
          ],
        ),
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final Shift shift;
  const _ShiftTile({required this.shift});

  @override
  Widget build(BuildContext context) {
    final isToday = shift.start.day == DateTime.now().day &&
        shift.start.month == DateTime.now().month;
    final dayLabel =
        isToday ? 'Today' : DateFormat('EEE, MMM d').format(shift.start);
    final timeFmt = DateFormat('h:mm a');
    final hrs = shift.hours;
    final hrsStr =
        hrs == hrs.roundToDouble() ? '${hrs.toInt()}h' : '${hrs.toStringAsFixed(1)}h';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(
                  '${timeFmt.format(shift.start)} – ${timeFmt.format(shift.end)}  ·  ${shift.role}',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(hrsStr,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
