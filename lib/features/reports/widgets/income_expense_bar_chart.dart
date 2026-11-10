import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:expense_tracker/features/reports/theme/chart_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  const IncomeExpenseBarChart({
    super.key,
    required this.points,
    this.currency = 'PKR',
    this.height = 240,
  });

  final List<MonthlyIncomeExpensePoint> points;
  final String currency;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.every((p) => p.income == 0 && p.expense == 0)) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No income/expense data yet.')),
      );
    }

    final maxY = points.fold<double>(0, (m, p) {
      final top = p.income > p.expense ? p.income : p.expense;
      return top > m ? top : m;
    });

    return Column(
      children: [
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY <= 0 ? 1 : maxY * 1.2,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: ChartColors.gridLine,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : '${value.toInt()}',
                      style: TextStyle(color: ChartColors.axisText, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) return const SizedBox.shrink();
                      final label = DateFormat('MMM').format(points[i].monthStart);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: TextStyle(color: ChartColors.axisText, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(points.length, (index) {
                final p = points[index];
                return BarChartGroupData(
                  x: index,
                  barsSpace: 6,
                  barRods: [
                    BarChartRodData(
                      toY: p.income,
                      color: ChartColors.teal,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: p.expense,
                      color: ChartColors.coral,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: ChartColors.teal, label: 'Income'),
            const SizedBox(width: 16),
            _LegendDot(color: ChartColors.coral, label: 'Expense'),
          ],
        ),
        const SizedBox(height: 12),
        ...points.reversed.map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(DateFormat('MMM yyyy').format(p.monthStart)),
                ),
                Text(
                  'Net ${CurrencyFormatter.format(p.net, currencyCode: currency)}',
                  style: TextStyle(
                    color: p.net >= 0 ? ChartColors.teal : ChartColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
