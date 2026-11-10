import 'package:expense_tracker/core/models/transaction_item.dart';

bool transactionMatchesSearch(TransactionItem item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  if (item.description?.toLowerCase().contains(q) ?? false) return true;
  if (item.categoryName?.toLowerCase().contains(q) ?? false) return true;
  if (item.accountName?.toLowerCase().contains(q) ?? false) return true;
  if (item.amount.toString().contains(q)) return true;

  return false;
}
