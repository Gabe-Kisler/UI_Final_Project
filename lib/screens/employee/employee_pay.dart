import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';

class EmployeePay extends StatelessWidget {
  const EmployeePay({super.key});

  @override
  Widget build(BuildContext context) {
    final pay = mockPayPeriod;
    final fmt = DateFormat('MMM d');
    final daysLeft = pay.end.difference(DateTime.now()).inDays.clamp(0, 99);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pay',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Current period card
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Label('CURRENT PAY PERIOD'),
                        const Spacer(),
                        Text(
                          '${fmt.format(pay.start)} – ${fmt.format(pay.end)}',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${pay.expectedPay.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('Expected payout',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _PayStat(
                            label: 'Pending',
                            value:
                                '\$${pay.pendingPay.toStringAsFixed(2)}'),
                        const SizedBox(width: 24),
                        _PayStat(
                            label: 'Days remaining',
                            value: '$daysLeft days'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Breakdown
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('PAY BREAKDOWN'),
                    const SizedBox(height: 14),
                    _BreakdownRow(
                        label: 'Regular (38.5 h)',
                        rate: '\$21.20/hr',
                        value: '\$816.20'),
                    _Divider(),
                    _BreakdownRow(
                        label: 'Overtime (0 h)',
                        rate: '\$31.80/hr',
                        value: '\$0.00'),
                    _Divider(),
                    _BreakdownRow(label: 'Tips', rate: '', value: '\$9.80'),
                    _Divider(),
                    _BreakdownRow(
                        label: 'Total',
                        rate: '',
                        value: '\$826.00',
                        bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // History
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('PAY HISTORY'),
                    const SizedBox(height: 14),
                    _HistoryTile(
                        period: 'Mar 16 – Mar 31',
                        amount: '\$1,243.60'),
                    _HistoryTile(
                        period: 'Mar 1 – Mar 15',
                        amount: '\$1,108.40'),
                    _HistoryTile(
                        period: 'Feb 16 – Feb 28',
                        amount: '\$987.20',
                        isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Local widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1));
}

class _PayStat extends StatelessWidget {
  final String label;
  final String value;
  const _PayStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ],
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.cardBorder, height: 20);
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String rate;
  final String value;
  final bool bold;
  const _BreakdownRow(
      {required this.label,
      required this.rate,
      required this.value,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: bold ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14)),
              if (rate.isNotEmpty)
                Text(rate,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: bold ? 16 : 14)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String period;
  final String amount;
  final bool isLast;
  const _HistoryTile(
      {required this.period, required this.amount, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Paid',
                    style: TextStyle(
                        color: AppColors.success, fontSize: 11)),
              ],
            ),
          ),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
