import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:expense_tracker/features/reports/theme/chart_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DailyExpenseBarChart extends StatelessWidget {
  const DailyExpenseBarChart({
    super.key,
    required this.points,
    this.height = 180,
  });

  final List<DailyExpensePoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((p) => p.amount > 0);
    if (!hasData) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No daily expenses this month',
            style: TextStyle(color: ChartColors.axisText),
          ),
        ),
      );
    }

    final maxY = points.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
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
                reservedSize: 36,
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
                  final day = value.toInt();
                  if (day < 1 || day > points.length) return const SizedBox.shrink();
                  if (day % 5 != 0 && day != 1 && day != points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$day',
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
              x: p.day,
              barRods: [
                BarChartRodData(
                  toY: p.amount,
                  color: ChartColors.teal,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
