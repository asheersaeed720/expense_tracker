import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';

class TransactionGroup {
  const TransactionGroup({
    required this.heading,
    required this.items,
  });

  final String heading;
  final List<TransactionItem> items;
}

class TransactionGrouper {
  TransactionGrouper._();

  static List<TransactionGroup> groupByDay(List<TransactionItem> items) {
    final map = <String, List<TransactionItem>>{};
    final order = <String>[];

    for (final item in items) {
      final key = _dateOnly(item.date);
      if (!map.containsKey(key)) {
        map[key] = [];
        order.add(key);
      }
      map[key]!.add(item);
    }

    return order.map((key) {
      final day = DateTime.parse(key);
      return TransactionGroup(
        heading: DateFormatter.transactionDate(day),
        items: map[key]!,
      );
    }).toList();
  }

  static String _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;
  }
}
