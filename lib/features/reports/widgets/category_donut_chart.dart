import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:expense_tracker/features/reports/theme/chart_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.slices,
    this.currency = 'PKR',
    this.size = 220,
  });

  final List<CategoryExpenseSlice> slices;
  final String currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, e) => s + e.amount);
    if (total <= 0) {
      return SizedBox(
        height: size,
        child: const Center(child: Text('No expense data for this period.')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: size,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: List.generate(slices.length, (index) {
                final slice = slices[index];
                final color = ColorUtils.fromHex(slice.colorHex) ??
                    ChartColors.donutPalette[index % ChartColors.donutPalette.length];
                return PieChartSectionData(
                  color: color,
                  value: slice.amount,
                  title: '${slice.percentageOf(total).toStringAsFixed(0)}%',
                  radius: 52,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...slices.map((slice) {
          final pct = slice.percentageOf(total);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(slice.name)),
                    Text(
                      CurrencyFormatter.format(slice.amount, currencyCode: currency),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: ChartColors.amber,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
