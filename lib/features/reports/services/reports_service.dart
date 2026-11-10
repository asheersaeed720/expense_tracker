import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsService {
  ReportsService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<DailyExpensePoint>> fetchDailyExpensesForMonth({
    required int year,
    required int month,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final rows = await _client
        .from('transactions')
        .select('amount, date')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', _dateOnly(start))
        .lte('date', _dateOnly(end));

    final daysInMonth = end.day;
    final totals = List<double>.filled(daysInMonth + 1, 0);
    for (final row in rows) {
      final date = DateTime.parse(row['date'] as String);
      final amount = (row['amount'] as num).toDouble();
      totals[date.day] += amount;
    }

    return List.generate(
      daysInMonth,
      (i) => DailyExpensePoint(day: i + 1, amount: totals[i + 1]),
    );
  }

  Future<MonthExpenseComparison> fetchMonthExpenseComparison({
    required int year,
    required int month,
  }) async {
    final current = await _totalExpensesForMonth(year: year, month: month);
    final prevMonth = DateTime(year, month - 1, 1);
    final previous = await _totalExpensesForMonth(
      year: prevMonth.year,
      month: prevMonth.month,
    );
    return MonthExpenseComparison(
      currentTotal: current,
      previousTotal: previous,
    );
  }

  Future<double> _totalExpensesForMonth({
    required int year,
    required int month,
  }) async {
    final userId = _userId;
    if (userId == null) return 0;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final rows = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', _dateOnly(start))
        .lte('date', _dateOnly(end));

    return rows.fold<double>(
      0,
      (sum, row) => sum + (row['amount'] as num).toDouble(),
    );
  }

  Future<List<CategoryExpenseSlice>> fetchExpenseByCategory(
    ReportsPeriod period,
  ) async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client
        .from('transactions')
        .select('amount, category_id, categories(id, name, color)')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', _dateOnly(period.start))
        .lte('date', _dateOnly(period.end));

    final map = <String, CategoryExpenseSlice>{};

    for (final row in rows) {
      final amount = (row['amount'] as num).toDouble();
      final category = row['categories'];
      final id = row['category_id'] as String? ?? 'uncategorized';
      String name = 'Uncategorized';
      String? color;
      if (category is Map<String, dynamic>) {
        name = category['name'] as String? ?? name;
        color = category['color'] as String?;
      }

      final existing = map[id];
      if (existing == null) {
        map[id] = CategoryExpenseSlice(
          categoryId: id,
          name: name,
          amount: amount,
          colorHex: color,
        );
      } else {
        map[id] = CategoryExpenseSlice(
          categoryId: id,
          name: name,
          amount: existing.amount + amount,
          colorHex: color ?? existing.colorHex,
        );
      }
    }

    final list = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  Future<List<MonthlyIncomeExpensePoint>> fetchLastSixMonthsTrend({
    required int year,
    required int month,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final anchor = DateTime(year, month, 1);
    final months = List.generate(6, (i) {
      return DateTime(anchor.year, anchor.month - (5 - i), 1);
    });

    final earliest = months.first;
    final latestEnd = DateTime(anchor.year, anchor.month + 1, 0);

    final rows = await _client
        .from('transactions')
        .select('amount, type, date')
        .eq('user_id', userId)
        .gte('date', _dateOnly(earliest))
        .lte('date', _dateOnly(latestEnd));

    final points = <MonthlyIncomeExpensePoint>[];
    for (final monthStart in months) {
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
      var income = 0.0;
      var expense = 0.0;

      for (final row in rows) {
        final date = DateTime.parse(row['date'] as String);
        if (date.isBefore(monthStart) || date.isAfter(monthEnd)) continue;
        final amount = (row['amount'] as num).toDouble();
        if (row['type'] == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }

      points.add(
        MonthlyIncomeExpensePoint(
          monthStart: monthStart,
          income: income,
          expense: expense,
        ),
      );
    }

    return points;
  }

  Future<List<AccountPeriodSummary>> fetchAccountSummaries(
    ReportsPeriod period,
  ) async {
    final userId = _userId;
    if (userId == null) return [];

    final accountRows = await _client
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('name');

    final accounts = accountRows.map(Account.fromJson).toList();
    if (accounts.isEmpty) return [];

    final inPeriod = await _client
        .from('transactions')
        .select('account_id, amount, type, date')
        .eq('user_id', userId)
        .gte('date', _dateOnly(period.start))
        .lte('date', _dateOnly(period.end));

    final afterPeriod = await _client
        .from('transactions')
        .select('account_id, amount, type, date')
        .eq('user_id', userId)
        .gt('date', _dateOnly(period.end));

    final summaries = <AccountPeriodSummary>[];

    for (final account in accounts) {
      var income = 0.0;
      var expense = 0.0;
      for (final row in inPeriod) {
        if (row['account_id'] != account.id) continue;
        final amount = (row['amount'] as num).toDouble();
        if (row['type'] == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }

      var netAfter = 0.0;
      for (final row in afterPeriod) {
        if (row['account_id'] != account.id) continue;
        final amount = (row['amount'] as num).toDouble();
        netAfter += row['type'] == 'income' ? amount : -amount;
      }

      final closingAtEnd = account.balance - netAfter;
      final opening = closingAtEnd - income + expense;

      summaries.add(
        AccountPeriodSummary(
          accountId: account.id,
          accountName: account.name,
          openingBalance: opening,
          income: income,
          expense: expense,
          closingBalance: closingAtEnd,
        ),
      );
    }

    return summaries;
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
