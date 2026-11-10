import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:expense_tracker/features/reports/services/reports_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService();
});

final reportsPeriodProvider = StateProvider<ReportsPeriod>((ref) {
  final now = DateTime.now();
  return ReportsPeriod.month(now.year, now.month);
});

final dashboardDailyExpensesProvider = FutureProvider<List<DailyExpensePoint>>((ref) async {
  final now = DateTime.now();
  return ref.read(reportsServiceProvider).fetchDailyExpensesForMonth(
        year: now.year,
        month: now.month,
      );
});

final dashboardExpenseComparisonProvider =
    FutureProvider<MonthExpenseComparison>((ref) async {
  final now = DateTime.now();
  return ref.read(reportsServiceProvider).fetchMonthExpenseComparison(
        year: now.year,
        month: now.month,
      );
});

final categoryBreakdownProvider =
    FutureProvider<List<CategoryExpenseSlice>>((ref) async {
  final period = ref.watch(reportsPeriodProvider);
  return ref.read(reportsServiceProvider).fetchExpenseByCategory(period);
});

final sixMonthTrendProvider =
    FutureProvider<List<MonthlyIncomeExpensePoint>>((ref) async {
  final period = ref.watch(reportsPeriodProvider);
  return ref.read(reportsServiceProvider).fetchLastSixMonthsTrend(
        year: period.end.year,
        month: period.end.month,
      );
});

final accountPeriodSummaryProvider =
    FutureProvider<List<AccountPeriodSummary>>((ref) async {
  final period = ref.watch(reportsPeriodProvider);
  return ref.read(reportsServiceProvider).fetchAccountSummaries(period);
});
