import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ManagerSchedule extends StatefulWidget {
  const ManagerSchedule({super.key});

  @override
  State<ManagerSchedule> createState() => _ManagerScheduleState();
}

class _ManagerScheduleState extends State<ManagerSchedule> {
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
    final weekShifts = controller.currentTeamShifts
        .where((shift) =>
            !shift.start.isBefore(_weekStart) &&
            shift.start.isBefore(_weekStart.add(const Duration(days: 7))))
        .toList();
    final dropRequests = weekShifts
        .where((shift) => shift.status == ShiftStatus.dropRequested)
        .toList();
    final pickupRequests = controller.currentTeamShifts
        .where((shift) => shift.status == ShiftStatus.pickupPending)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showShiftEditor(context, controller),
        label: const Text('Create shift'),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Schedule',
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
              if (dropRequests.isNotEmpty || pickupRequests.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Manager approvals',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...dropRequests.map(
                        (shift) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ApprovalTile(
                            title:
                                '${controller.employeeName(shift.assignedUserId)} requested to drop ${shift.roleName}',
                            subtitle: _shiftTime(shift),
                            buttonLabel: 'Approve drop',
                            onPressed: () =>
                                controller.approveShiftDrop(shift.id),
                          ),
                        ),
                      ),
                      ...pickupRequests.map(
                        (shift) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ApprovalTile(
                            title:
                                '${controller.employeeName(shift.pickupCandidateUserId!)} wants to pick up ${shift.roleName}',
                            subtitle: _shiftTime(shift),
                            buttonLabel: 'Approve pickup',
                            onPressed: () =>
                                controller.approveShiftPickup(shift.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = _weekStart.add(Duration(days: index));
                    final dayShifts = weekShifts
                        .where((shift) => _sameDay(shift.start, day))
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            if (dayShifts.isEmpty)
                              const Text('No scheduled shifts.',
                                  style:
                                      TextStyle(color: AppColors.textSecondary))
                            else
                              ...dayShifts.map(
                                (shift) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ManagerShiftTile(
                                    shift: shift,
                                    employeeName: controller
                                        .employeeName(shift.assignedUserId),
                                    onEdit: () => _showShiftEditor(
                                        context, controller,
                                        shift: shift),
                                    onDuplicate: () =>
                                        controller.duplicateShift(shift.id),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showShiftEditor(BuildContext context, controller,
      {WorkShift? shift}) async {
    final employees = controller.teamUsers
        .where((user) => user.id != controller.currentUser!.id)
        .toList();
    String selectedUserId = shift?.assignedUserId ?? employees.first.id;
    final roleController =
        TextEditingController(text: shift?.roleName ?? 'Cashier');
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd')
          .format(shift?.start ?? DateTime.now().add(const Duration(days: 1))),
    );
    final startController = TextEditingController(
        text: DateFormat('HH:mm').format(shift?.start ?? DateTime.now()));
    final endController = TextEditingController(
        text: DateFormat('HH:mm').format(
            shift?.end ?? DateTime.now().add(const Duration(hours: 8))));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shift == null ? 'Create shift' : 'Edit shift',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedUserId,
                dropdownColor: AppColors.surfaceVariant,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: employees
                    .map((employee) => DropdownMenuItem(
                        value: employee.id, child: Text(employee.fullName)))
                    .toList(),
                onChanged: (value) => setModalState(
                    () => selectedUserId = value ?? selectedUserId),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: roleController,
                  decoration:
                      const InputDecoration(labelText: 'Role for shift')),
              const SizedBox(height: 12),
              TextField(
                  controller: dateController,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(
                              labelText: 'Start (24h HH:MM)'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(
                              labelText: 'End (24h HH:MM)'))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final start = _parseDateTime(
                        dateController.text, startController.text);
                    final end =
                        _parseDateTime(dateController.text, endController.text);
                    if (start == null || end == null || !end.isAfter(start)) {
                      return;
                    }

                    if (shift == null) {
                      controller.createShift(
                        userId: selectedUserId,
                        roleName: roleController.text,
                        start: start,
                        end: end,
                      );
                    } else {
                      controller.updateShift(
                        shiftId: shift.id,
                        userId: selectedUserId,
                        roleName: roleController.text,
                        start: start,
                        end: end,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child:
                        Text(shift == null ? 'Create shift' : 'Save changes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime? _parseDateTime(String date, String time) {
    final parts = date.split('-');
    final timeParts = time.split(':');
    if (parts.length != 3 || timeParts.length != 2) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if ([year, month, day, hour, minute].contains(null)) {
      return null;
    }

    return DateTime(year!, month!, day!, hour!, minute!);
  }

  String _shiftTime(WorkShift shift) {
    return '${DateFormat('EEE, MMM d').format(shift.start)}  ${DateFormat('h:mm a').format(shift.start)} - ${DateFormat('h:mm a').format(shift.end)}';
  }
}

class _ManagerShiftTile extends StatelessWidget {
  final WorkShift shift;
  final String employeeName;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;

  const _ManagerShiftTile({
    required this.shift,
    required this.employeeName,
    required this.onEdit,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shift.roleName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(employeeName,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('h:mm a').format(shift.start)} - ${DateFormat('h:mm a').format(shift.end)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.surface,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'duplicate') {
                    onDuplicate();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: 'edit',
                      child:
                          Text('Edit', style: TextStyle(color: Colors.white))),
                  PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate next week',
                          style: TextStyle(color: Colors.white))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_statusText(shift.status),
                style: TextStyle(color: _statusColor(shift.status))),
          ),
        ],
      ),
    );
  }

  String _statusText(ShiftStatus status) {
    return switch (status) {
      ShiftStatus.scheduled => 'Scheduled',
      ShiftStatus.dropRequested => 'Waiting for drop approval',
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

class _ApprovalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ApprovalTile({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
