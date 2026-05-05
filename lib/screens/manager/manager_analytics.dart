import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../theme/app_theme.dart';

class ManagerAnalytics extends StatelessWidget {
  const ManagerAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final employees = controller.teamUsers
        .where((user) => user.id != controller.currentUser!.id)
        .toList();
    final payrolls =
        employees.map((user) => controller.paycheckForUser(user.id)).toList();
    final grossTotal =
        payrolls.fold<double>(0, (sum, pay) => sum + pay.grossPay);
    final netTotal = payrolls.fold<double>(0, (sum, pay) => sum + pay.netPay);
    final stateTotal =
        payrolls.fold<double>(0, (sum, pay) => sum + pay.stateWithholding);
    final federalTotal = payrolls.fold<double>(
        0, (sum, pay) => sum + pay.federalWithholding + pay.ficaWithholding);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payroll Analytics',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _KpiCard(
                          label: 'Gross payroll',
                          value: '\$${grossTotal.toStringAsFixed(0)}')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _KpiCard(
                          label: 'Estimated take-home',
                          value: '\$${netTotal.toStringAsFixed(0)}')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _KpiCard(
                          label: 'Federal + FICA',
                          value: '\$${federalTotal.toStringAsFixed(0)}')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _KpiCard(
                          label: 'State withholding',
                          value: '\$${stateTotal.toStringAsFixed(0)}')),
                ],
              ),
              const SizedBox(height: 14),
              Container(
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
                    const Text('Take-home Pay by Employee',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: payrolls.fold<double>(
                                  0,
                                  (sum, pay) =>
                                      pay.netPay > sum ? pay.netPay : sum) *
                              1.2,
                          barTouchData: BarTouchData(enabled: false),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= employees.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      employees[index]
                                          .fullName
                                          .split(' ')
                                          .first,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(
                            employees.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: payrolls[index].netPay,
                                  width: 26,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.accent
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
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
                    const Text('Employee Payroll Detail',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...List.generate(employees.length, (index) {
                      final employee = employees[index];
                      final pay = payrolls[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                                    Text(employee.fullName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${employee.stateCode} withholding • ${pay.regularHours.toStringAsFixed(1)} regular hrs • ${pay.overtimeHours.toStringAsFixed(1)} OT hrs',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text('\$${pay.netPay.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ],
                          ),
                        ),
                      );
                    }),
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

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({
    required this.label,
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
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
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
