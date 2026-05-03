import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../role_select_screen.dart';

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, dateStr),
              const SizedBox(height: 16),
              _buildLaborCost(),
              const SizedBox(height: 12),
              _buildStatsRow(),
              const SizedBox(height: 12),
              _buildAlerts(),
              const SizedBox(height: 12),
              _buildShiftGaps(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String dateStr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Overview",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            Text(dateStr,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
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
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Center(
              child: Text('G',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLaborCost() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('LABOR COST'),
          const SizedBox(height: 2),
          const Text(
            '\$4,312',
            style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 80, child: _MiniBarChart()),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatChip(
            value: '14.2h',
            label: 'Overtime\nthis period',
            valueColor: AppColors.warning),
        const SizedBox(width: 8),
        _StatChip(value: '\$13.84', label: 'Avg labor\ncost /hr'),
        const SizedBox(width: 8),
        _StatChip(
            value: '96%',
            label: 'Shift\ncoverage',
            valueColor: AppColors.success),
        const SizedBox(width: 8),
        _StatChip(value: '312', label: 'Hours\nlogged /w'),
      ],
    );
  }

  Widget _buildAlerts() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Label('ALERTS'),
              const Spacer(),
              Text('view all',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...mockAlerts.map((a) => _AlertRow(alert: a)),
        ],
      ),
    );
  }

  Widget _buildShiftGaps() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('SHIFT GAPS'),
          const SizedBox(height: 12),
          ...mockShiftGaps.map((g) => _GapRow(gap: g)),
        ],
      ),
    );
  }
}

// ── Chart ────────────────────────────────────────────────────────────────────

class _MiniBarChart extends StatelessWidget {
  final List<double> data = weeklyLaborCost;
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'Su'];

  @override
  Widget build(BuildContext context) {
    final max = data.reduce((a, b) => a > b ? a : b);
    // Highlight today (index 3 = Thursday in the mock week)
    const todayIndex = 3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: max * 1.25,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                _days[v.toInt()],
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          data.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: i == todayIndex
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.4),
                width: 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1),
      );
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  const _StatChip({required this.value, required this.label, this.valueColor});

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
                style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(label,
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

class _AlertRow extends StatelessWidget {
  final ShiftAlert alert;
  const _AlertRow({required this.alert});

  IconData get _icon => switch (alert.type) {
        AlertType.missedClockIn => Icons.access_time_rounded,
        AlertType.overtime => Icons.trending_up_rounded,
        AlertType.swapRequest => Icons.swap_horiz_rounded,
      };

  Color get _color => switch (alert.type) {
        AlertType.missedClockIn => AppColors.error,
        AlertType.overtime => AppColors.warning,
        AlertType.swapRequest => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: _color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(alert.subtitle,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  final ShiftGap gap;
  const _GapRow({required this.gap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${gap.role}  ·  ${gap.timeRange}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(gap.reason,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted, size: 13),
        ],
      ),
    );
  }
}
