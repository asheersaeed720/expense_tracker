import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:expense_tracker/features/reports/providers/reports_providers.dart';
import 'package:expense_tracker/features/reports/widgets/account_summary_table.dart';
import 'package:expense_tracker/features/reports/widgets/category_donut_chart.dart';
import 'package:expense_tracker/features/reports/widgets/income_expense_bar_chart.dart';
import 'package:expense_tracker/features/reports/widgets/report_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _pickMonth(BuildContext context, WidgetRef ref) async {
    final period = ref.read(reportsPeriodProvider);
    final initial = period.start;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    ref.read(reportsPeriodProvider.notifier).state =
        ReportsPeriod.month(picked.year, picked.month);
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final period = ref.read(reportsPeriodProvider);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: period.start, end: period.end),
    );
    if (range == null) return;

    ref.read(reportsPeriodProvider.notifier).state = ReportsPeriod(
      start: range.start,
      end: range.end,
      label: 'Custom range',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportsPeriodProvider);
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';

    final categoryAsync = ref.watch(categoryBreakdownProvider);
    final trendAsync = ref.watch(sixMonthTrendProvider);
    final accountAsync = ref.watch(accountPeriodSummaryProvider);

    final periodLabel = period.label ??
        '${period.start.day}/${period.start.month}/${period.start.year}'
        ' – ${period.end.day}/${period.end.month}/${period.end.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryBreakdownProvider);
          ref.invalidate(sixMonthTrendProvider);
          ref.invalidate(accountPeriodSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Period', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(periodLabel),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () {
                            final now = DateTime.now();
                            ref.read(reportsPeriodProvider.notifier).state =
                                ReportsPeriod.month(now.year, now.month);
                          },
                          child: const Text('This month'),
                        ),
                        OutlinedButton(
                          onPressed: () => _pickMonth(context, ref),
                          child: const Text('Pick month'),
                        ),
                        OutlinedButton(
                          onPressed: () => _pickCustomRange(context, ref),
                          child: const Text('Custom range'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Expense by category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: categoryAsync.when(
                  loading: () => const ReportSkeleton(height: 280),
                  error: (e, _) => Text(e.toString()),
                  data: (slices) {
                    final total =
                        slices.fold<double>(0, (s, e) => s + e.amount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (total > 0)
                          Text(
                            'Total: ${CurrencyFormatter.format(total, currencyCode: currency)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        const SizedBox(height: 8),
                        CategoryDonutChart(
                          slices: slices,
                          currency: currency,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Income vs expense (6 months)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: trendAsync.when(
                  loading: () => const ReportSkeleton(height: 300),
                  error: (e, _) => Text(e.toString()),
                  data: (points) => IncomeExpenseBarChart(
                    points: points,
                    currency: currency,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Account summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: accountAsync.when(
                  loading: () => const ReportSkeleton(height: 160),
                  error: (e, _) => Text(e.toString()),
                  data: (rows) => AccountSummaryTable(
                    rows: rows,
                    currency: currency,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
