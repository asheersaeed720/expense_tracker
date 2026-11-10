import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:expense_tracker/features/reports/providers/reports_providers.dart';
import 'package:expense_tracker/features/reports/theme/chart_colors.dart';
import 'package:expense_tracker/features/reports/widgets/daily_expense_bar_chart.dart';
import 'package:expense_tracker/features/reports/widgets/report_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonthlyExpenseOverviewCard extends ConsumerWidget {
  const MonthlyExpenseOverviewCard({super.key, this.onViewReports});

  final VoidCallback? onViewReports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dashboardDailyExpensesProvider);
    final comparisonAsync = ref.watch(dashboardExpenseComparisonProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Monthly overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (onViewReports != null)
                  TextButton(onPressed: onViewReports, child: const Text('View Reports')),
              ],
            ),
            const SizedBox(height: 8),
            dailyAsync.when(
              loading: () => const ReportSkeleton(height: 180),
              error: (e, _) => Text(e.toString()),
              data: (points) => DailyExpenseBarChart(points: points),
            ),
            const SizedBox(height: 12),
            comparisonAsync.when(
              loading: () => const ReportSkeleton(height: 40),
              error: (e, _) => Text(e.toString()),
              data: (comparison) => Text(
                comparison.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _comparisonColor(comparison),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _comparisonColor(MonthExpenseComparison comparison) {
    final change = comparison.percentChange;
    if (change == null) return ChartColors.axisText;
    if (change > 0) return ChartColors.coral;
    if (change < 0) return ChartColors.teal;
    return ChartColors.amber;
  }
}
