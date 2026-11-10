import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/transactions/models/transaction_filters.dart';
import 'package:flutter/material.dart';

class TransactionSummaryHeader extends StatelessWidget {
  const TransactionSummaryHeader({
    super.key,
    required this.totals,
    this.currency = 'PKR',
  });

  final FilteredTotals totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'Income',
                value: CurrencyFormatter.format(totals.income, currencyCode: currency),
                color: const Color(0xFF34D399),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(
                label: 'Expense',
                value: CurrencyFormatter.format(totals.expense, currencyCode: currency),
                color: const Color(0xFFF87171),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(
                label: 'Net',
                value: CurrencyFormatter.format(totals.net, currencyCode: currency),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
