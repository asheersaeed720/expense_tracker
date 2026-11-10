import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:expense_tracker/features/transactions/models/transaction_filters.dart';
import 'package:expense_tracker/features/transactions/utils/transaction_grouper.dart';
import 'package:expense_tracker/features/transactions/utils/transaction_search.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionItem _item({
  String id = 't1',
  String? description,
  String? categoryName,
  String? accountName,
  double amount = 100,
  DateTime? date,
}) {
  return TransactionItem(
    id: id,
    type: TransactionType.expense,
    amount: amount,
    date: date ?? DateTime(2026, 11, 10),
    accountId: 'acc-1',
    description: description,
    categoryName: categoryName,
    accountName: accountName,
  );
}

void main() {
  group('TransactionFilters.resolveRange', () {
    test('this month starts on day 1 and ends on the last day', () {
      final now = DateTime.now();
      final (start, end) = const TransactionFilters().resolveRange();

      expect(start, DateTime(now.year, now.month, 1));
      expect(end, DateTime(now.year, now.month + 1, 0));
    });

    test('last month is the previous calendar month', () {
      final now = DateTime.now();
      final (start, end) = const TransactionFilters(
        datePreset: TransactionDatePreset.lastMonth,
      ).resolveRange();

      expect(start, DateTime(now.year, now.month - 1, 1));
      expect(end, DateTime(now.year, now.month, 0));
    });

    test('custom range keeps the dates the user picked', () {
      final startDate = DateTime(2026, 1, 5);
      final endDate = DateTime(2026, 1, 20);
      final (start, end) = TransactionFilters(
        datePreset: TransactionDatePreset.custom,
        customStart: startDate,
        customEnd: endDate,
      ).resolveRange();

      expect(start, startDate);
      expect(end, endDate);
    });
  });

  group('search and grouping', () {
    test('blank search matches every transaction', () {
      expect(transactionMatchesSearch(_item(description: 'Tea'), '   '), isTrue);
    });

    test('search matches description, category, account, and amount', () {
      final item = _item(
        description: 'Coffee with Ali',
        categoryName: 'Food',
        accountName: 'Cash in Hand',
        amount: 250,
      );

      expect(transactionMatchesSearch(item, 'coffee'), isTrue);
      expect(transactionMatchesSearch(item, 'FOOD'), isTrue);
      expect(transactionMatchesSearch(item, 'cash'), isTrue);
      expect(transactionMatchesSearch(item, '250'), isTrue);
      expect(transactionMatchesSearch(item, 'rent'), isFalse);
    });

    test('groupByDay keeps input order and puts the same day together', () {
      final groups = TransactionGrouper.groupByDay([
        _item(id: 'a', date: DateTime(2026, 11, 10, 9)),
        _item(id: 'b', date: DateTime(2026, 11, 9, 18)),
        _item(id: 'c', date: DateTime(2026, 11, 10, 21)),
      ]);

      expect(groups.map((g) => g.items.map((i) => i.id).toList()), [
        ['a', 'c'],
        ['b'],
      ]);
    });
  });

  group('MonthExpenseComparison', () {
    test('percent change and message follow the previous month', () {
      const up = MonthExpenseComparison(currentTotal: 150, previousTotal: 100);
      expect(up.percentChange, 50);
      expect(up.message, 'You spent 50% more than last month.');

      const down = MonthExpenseComparison(currentTotal: 50, previousTotal: 100);
      expect(down.message, 'You spent 50% less than last month.');

      const none = MonthExpenseComparison(currentTotal: 80, previousTotal: 0);
      expect(none.percentChange, isNull);
      expect(none.message, 'No expenses last month to compare.');

      const empty = MonthExpenseComparison(currentTotal: 0, previousTotal: 0);
      expect(empty.message, 'No expenses recorded this month yet.');
    });
  });

  test('filtered net is income minus expense', () {
    const totals = FilteredTotals(income: 5000, expense: 1250.5);
    expect(totals.net, 3749.5);
  });
}
