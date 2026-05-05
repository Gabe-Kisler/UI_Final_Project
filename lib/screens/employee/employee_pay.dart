import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_scope.dart';
import '../../theme/app_theme.dart';

class EmployeePay extends StatelessWidget {
  const EmployeePay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final user = controller.currentUser!;
    final preview = controller.paycheckForUser(user.id);
    final periodStart = controller.payPeriodStart();
    final periodEnd = periodStart.add(const Duration(days: 14));
    final taxProfile = controller.taxProfileFor(user.stateCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pay Preview',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _PayCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Current Pay Period',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(
                          '${DateFormat('MMM d').format(periodStart)} - ${DateFormat('MMM d').format(periodEnd)}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('\$${preview.netPay.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold)),
                    const Text('Estimated take-home pay',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            label: 'Regular hours',
                            value:
                                '${preview.regularHours.toStringAsFixed(1)}h',
                          ),
                        ),
                        Expanded(
                          child: _MiniMetric(
                            label: 'Overtime',
                            value:
                                '${preview.overtimeHours.toStringAsFixed(1)}h',
                          ),
                        ),
                        Expanded(
                          child: _MiniMetric(
                            label: 'State',
                            value: user.stateCode,
                          ),
                        ),
                        Expanded(
                          child: _MiniMetric(
                            label: 'Hourly rate',
                            value: user.hourlyRate > 0
                                ? '\$${user.hourlyRate.toStringAsFixed(2)}'
                                : 'Pending',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _PayCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payroll Breakdown',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    _BreakdownRow(label: 'Gross pay', value: preview.grossPay),
                    _BreakdownRow(
                        label: 'Federal withholding',
                        value: -preview.federalWithholding),
                    _BreakdownRow(
                      label: 'State withholding (${taxProfile.name})',
                      value: -preview.stateWithholding,
                    ),
                    _BreakdownRow(
                        label: 'FICA', value: -preview.ficaWithholding),
                    const Divider(color: AppColors.cardBorder),
                    _BreakdownRow(
                        label: 'Estimated net pay',
                        value: preview.netPay,
                        emphasize: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _PayCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('How this is calculated',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text(
                      'Take-home pay updates from your scheduled hours, overtime, federal withholding, FICA, the manager-assigned hourly rate, and the state selected on your account. Edit your state in Profile if your withholding location changes.',
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.5),
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
}

class _PayCard extends StatelessWidget {
  final Widget child;

  const _PayCard({required this.child});

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

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(symbol: '\$').format(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasize ? Colors.white : AppColors.textSecondary,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            formatted,
            style: TextStyle(
              color: Colors.white,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              fontSize: emphasize ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }
}
