import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';

class ManagerAnalytics extends StatelessWidget {
  const ManagerAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildKpiRow(),
              const SizedBox(height: 12),
              _buildWeeklyChart(),
              const SizedBox(height: 12),
              _buildCoverageCard(),
              const SizedBox(height: 12),
              _buildTopWorkers(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
              label: 'Total Labor',
              value: '\$4,312',
              trend: '+2.1%',
              positive: false),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
              label: 'Avg Cost/Hr',
              value: '\$13.84',
              trend: '-0.4%',
              positive: true),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
              label: 'OT Hours',
              value: '14.2h',
              trend: '+1.8h',
              positive: false),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final data = weeklyLaborCost;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'Su'];
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('WEEKLY LABOR COST'),
          const SizedBox(height: 4),
          Text('\$${data.reduce((a, b) => a + b).toStringAsFixed(0)} this week',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.surfaceVariant,
                    getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
                      '\$${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(days[v.toInt()],
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.cardBorder, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  data.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageCard() {
    return _Card(
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 3,
                centerSpaceRadius: 22,
                sections: [
                  PieChartSectionData(
                    value: 96,
                    color: AppColors.success,
                    title: '96%',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    radius: 42,
                  ),
                  PieChartSectionData(
                    value: 4,
                    color: AppColors.error.withValues(alpha: 0.35),
                    title: '',
                    radius: 42,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('SHIFT COVERAGE'),
                const SizedBox(height: 10),
                _LegendRow(
                    color: AppColors.success,
                    label: 'Covered',
                    value: '96%'),
                const SizedBox(height: 6),
                _LegendRow(
                    color: AppColors.error,
                    label: 'Uncovered',
                    value: '4%'),
                const SizedBox(height: 10),
                Text('3 open gaps this week',
                    style: TextStyle(
                        color: AppColors.warning, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopWorkers() {
    final workers = [
      ('Kim L', 'Warehouse', '41.5h', true),
      ('Eli Smith', 'Cashier', '38.5h', false),
      ('Jimmy T', 'Support', '35.0h', true),
      ('George H', 'Cashier', '32.0h', false),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('HOURS BY EMPLOYEE — THIS WEEK'),
          const SizedBox(height: 14),
          ...workers.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(w.$1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: double.parse(
                                  w.$3.replaceAll('h', '')) /
                              50,
                          backgroundColor: AppColors.cardBorder,
                          color: w.$4
                              ? AppColors.warning
                              : AppColors.primary,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(w.$3,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              )),
        ],
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
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1));
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool positive;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.trend,
      required this.positive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(trend,
              style: TextStyle(
                  color: positive ? AppColors.success : AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}
