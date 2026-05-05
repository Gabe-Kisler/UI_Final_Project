import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ManagerEmployees extends StatelessWidget {
  const ManagerEmployees({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final employees = controller.teamUsers
        .where((user) => user.id != controller.currentUser!.id)
        .toList();
    final invites = controller.currentTeamInvites;

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
                  const Text('Team',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _showInviteSheet(context, controller),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Invite employee'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    const Text('Active Team Members',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...employees.map(
                      (employee) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EmployeeTile(employee: employee),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pending Email Invites',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (invites.isEmpty)
                      const Text('No pending invites.',
                          style: TextStyle(color: AppColors.textSecondary))
                    else
                      ...invites.map(
                        (invite) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InviteTile(invite: invite),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInviteSheet(BuildContext context, controller) async {
    final emailController = TextEditingController();
    var role = UserRole.employee;

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
              const Text('Send Team Invite',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Employee email'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: role,
                dropdownColor: AppColors.surfaceVariant,
                decoration: const InputDecoration(labelText: 'Assign role'),
                items: const [
                  DropdownMenuItem(
                      value: UserRole.employee, child: Text('Employee')),
                  DropdownMenuItem(
                      value: UserRole.manager, child: Text('Manager')),
                ],
                onChanged: (value) =>
                    setModalState(() => role = value ?? UserRole.employee),
              ),
              const SizedBox(height: 16),
              const Text(
                'The employee registers with the same email, creates a password and username, then automatically joins the team.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Managers assign hourly rate after the employee joins.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final error = await controller.sendInvite(
                      email: emailController.text,
                      role: role,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          error ??
                              'Invite email sent to ${emailController.text}.',
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Create email invite'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final AppUser employee;

  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final paycheck = controller.paycheckForUser(employee.id);
    final isClockedIn = controller.openEntryForUser(employee.id) != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                child: Text(employee.initials,
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.fullName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(employee.email,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isClockedIn
                          ? AppColors.success
                          : AppColors.surfaceVariant)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(isClockedIn ? 'Clocked In' : 'Off Clock',
                    style: TextStyle(
                        color: isClockedIn
                            ? AppColors.success
                            : AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<UserRole>(
                  initialValue: employee.role,
                  dropdownColor: AppColors.surfaceVariant,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.employee, child: Text('Employee')),
                    DropdownMenuItem(
                        value: UserRole.manager, child: Text('Manager')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateUserRole(employee.id, value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: employee.hourlyRate.toStringAsFixed(2),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Hourly rate'),
                  onFieldSubmitted: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null) {
                      controller.updateHourlyRate(employee.id, parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaPill(label: 'State', value: employee.stateCode),
              const SizedBox(width: 8),
              _MetaPill(
                  label: 'Take-home',
                  value: '\$${paycheck.netPay.toStringAsFixed(0)}'),
              const SizedBox(width: 8),
              _MetaPill(
                  label: 'Updated',
                  value: DateFormat('MMM d').format(DateTime.now())),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmRemoval(context, controller),
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Remove from team'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoval(BuildContext context, controller) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove Employee'),
        content: Text(
          'Remove ${employee.fullName} from this team? Their future assigned shifts will be opened back up.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove != true || !context.mounted) {
      return;
    }

    await controller.removeEmployee(employee.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${employee.fullName} was removed from the team.')),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final TeamInvite invite;

  const _InviteTile({required this.invite});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final pending = invite.status == InviteStatus.pending;

    return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite.email,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${invite.role.name} invite • pay set after join • ${DateFormat('MMM d, h:mm a').format(invite.sentAt)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (pending)
            TextButton(
              onPressed: () => controller.revokeInvite(invite.id),
              child: const Text('Revoke'),
            )
          else
            Text(invite.status.name,
                style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetaPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
