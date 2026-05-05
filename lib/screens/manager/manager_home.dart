import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final team = controller.currentTeam!;
    final users = controller.teamUsers
        .where((user) => user.role == UserRole.employee)
        .toList();
    final openEntries = users
        .where((user) => controller.openEntryForUser(user.id) != null)
        .length;
    final pendingDrops = controller.currentTeamShifts
        .where((shift) => shift.status == ShiftStatus.dropRequested)
        .length;
    final pendingPickups = controller.currentTeamShifts
        .where((shift) => shift.status == ShiftStatus.pickupPending)
        .length;
    final payroll = users.fold<double>(
        0, (sum, user) => sum + controller.paycheckForUser(user.id).grossPay);

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
                      Text(team.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    color: AppColors.surfaceVariant,
                    onSelected: (value) {
                      if (value == 'rename_team') {
                        _showRenameDialog(context, controller);
                      } else if (value == 'logout') {
                        controller.logout();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: 'rename_team',
                          child: Text('Rename team',
                              style: TextStyle(color: Colors.white))),
                      PopupMenuItem(
                          value: 'logout',
                          child: Text('Sign out',
                              style: TextStyle(color: Colors.white))),
                    ],
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _HeroCard(
                  totalPayroll: payroll,
                  teamSize: users.length,
                  openEntries: openEntries),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _MetricCard(
                          title: 'Pending shift drops',
                          value: '$pendingDrops')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _MetricCard(
                          title: 'Pending pickups', value: '$pendingPickups')),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Manager Actions',
                child: Column(
                  children: [
                    _ActionTile(
                      title: 'Approve dropped shifts',
                      subtitle:
                          'Review employee drop requests before shifts become open for pickup.',
                      trailing: '$pendingDrops waiting',
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      title: 'Approve pickups',
                      subtitle:
                          'Assign open shifts to employees after manager review.',
                      trailing: '$pendingPickups waiting',
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      title: 'Invite staff by email',
                      subtitle:
                          'Employees create their account with the invited email and join the team automatically.',
                      trailing:
                          '${controller.currentTeamInvites.where((invite) => invite.status == InviteStatus.pending).length} pending',
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

  Future<void> _showRenameDialog(BuildContext context, controller) async {
    final teamName =
        TextEditingController(text: controller.currentTeam?.name ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rename team', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: teamName,
          decoration: const InputDecoration(labelText: 'Team name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              controller.updateTeamName(teamName.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double totalPayroll;
  final int teamSize;
  final int openEntries;

  const _HeroCard({
    required this.totalPayroll,
    required this.teamSize,
    required this.openEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3568FF), Color(0xFF0F9D8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live workforce overview',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text('\$${totalPayroll.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold)),
          const Text('Projected gross payroll this pay period',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _HeroStat(label: 'Employees', value: '$teamSize')),
              Expanded(
                  child: _HeroStat(
                      label: 'Clocked in now', value: '$openEntries')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({
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
                  fontSize: 22)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
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
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(trailing,
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
