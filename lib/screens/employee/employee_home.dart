import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final user = controller.currentUser!;
    final periodStart = controller.payPeriodStart();
    final periodEnd = periodStart.add(const Duration(days: 14));
    final preview = controller.paycheckForUser(user.id);
    final weekStart = controller.startOfWeek(DateTime.now());
    final workedHours = controller.workedHoursForWeek(user.id, weekStart);
    final openEntry = controller.openEntryForUser(user.id);
    final shifts = controller.shiftsForUser(user.id)
      ..sort((a, b) => a.start.compareTo(b.start));
    final upcoming = shifts
        .where((shift) => shift.end.isAfter(DateTime.now()))
        .take(3)
        .toList();
    final taxProfile = controller.taxProfileFor(user.stateCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back',
                          style: TextStyle(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.85))),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    color: AppColors.surfaceVariant,
                    onSelected: (value) {
                      if (value == 'logout') {
                        controller.logout();
                      } else if (value == 'edit_profile') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.surface,
                          builder: (_) => const _ProfileSheet(),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: 'edit_profile',
                          child: Text('Edit profile',
                              style: TextStyle(color: Colors.white))),
                      PopupMenuItem(
                          value: 'logout',
                          child: Text('Sign out',
                              style: TextStyle(color: Colors.white))),
                    ],
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(user.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _PanelLabel('Clock In'),
                        const Spacer(),
                        Text(
                          openEntry == null
                              ? 'Not clocked in'
                              : 'Clocked in live',
                          style: TextStyle(
                              color: openEntry == null
                                  ? AppColors.error
                                  : AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('h:mm a').format(DateTime.now()),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (openEntry != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Current shift started ${DateFormat('h:mm a').format(openEntry.clockIn)}',
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: openEntry == null
                            ? controller.clockIn
                            : controller.clockOut,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(openEntry == null
                              ? 'Clock In With Workplace Account'
                              : 'Clock Out'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          title: 'Hours worked this week',
                          value: '${workedHours.toStringAsFixed(1)}h')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                          title: 'Expected take-home',
                          value: '\$${preview.netPay.toStringAsFixed(0)}')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          title: 'Home state', value: user.stateCode)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                          title: 'Hourly rate',
                          value: user.hourlyRate > 0
                              ? '\$${user.hourlyRate.toStringAsFixed(2)}/hr'
                              : 'Pending')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          title: 'State withholding',
                          value:
                              '${(taxProfile.withholdingRate * 100).toStringAsFixed(2)}%')),
                  const SizedBox(width: 10),
                  const Expanded(
                      child:
                          _StatCard(title: 'Pay access', value: 'Read only')),
                ],
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _PanelLabel('Upcoming Shifts'),
                        const Spacer(),
                        Text('${upcoming.length} scheduled',
                            style: const TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      const Text('No upcoming shifts yet.',
                          style: TextStyle(color: AppColors.textSecondary))
                    else
                      ...upcoming.map(
                        (shift) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ShiftRow(
                              shift: shift, employeeName: user.fullName),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _PanelLabel('Paycheck Preview'),
                        const Spacer(),
                        Text(
                          '${DateFormat('MMM d').format(periodStart)} - ${DateFormat('MMM d').format(periodEnd)}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${preview.netPay.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                        'Estimated take-home based on scheduled hours and withholding settings.',
                        style: TextStyle(
                            color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late String _stateCode;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final user = ShiftSyncScope.of(context).currentUser!;
    _nameController = TextEditingController(text: user.fullName);
    _usernameController = TextEditingController(text: user.username);
    _stateCode = user.stateCode;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile & Tax Info',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _stateCode,
            dropdownColor: AppColors.surfaceVariant,
            decoration: const InputDecoration(labelText: 'Home state'),
            items: controller.states
                .map((state) => DropdownMenuItem(
                    value: state.code,
                    child: Text('${state.name} (${state.code})')))
                .toList(),
            onChanged: (value) =>
                setState(() => _stateCode = value ?? _stateCode),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_usernameController.text.trim().isEmpty) {
                  return;
                }
                controller.updateProfile(
                  fullName: _nameController.text,
                  stateCode: _stateCode,
                  username: _usernameController.text,
                );
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Save changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final WorkShift shift;
  final String employeeName;

  const _ShiftRow({
    required this.shift,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        '${DateFormat('EEE, MMM d').format(shift.start)}  ${DateFormat('h:mm a').format(shift.start)} - ${DateFormat('h:mm a').format(shift.end)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shift.roleName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Text(time,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('${shift.hours.toStringAsFixed(1)}h',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _PanelLabel extends StatelessWidget {
  final String text;

  const _PanelLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
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
          Text(title, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
        ],
      ),
    );
  }
}
