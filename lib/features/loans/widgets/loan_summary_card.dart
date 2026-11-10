import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class LoanSummaryCard extends StatelessWidget {
  const LoanSummaryCard({
    super.key,
    required this.type,
    required this.summary,
    this.currency = 'PKR',
  });

  final LoanType type;
  final LoanTabSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final lentLabel = type == LoanType.given ? 'Total lent' : 'Total borrowed';
    final outstandingLabel =
        type == LoanType.given ? 'Outstanding' : 'You owe';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$lentLabel: ${CurrencyFormatter.format(summary.totalAmount, currencyCode: currency)}'
              '  |  '
              '$outstandingLabel: ${CurrencyFormatter.format(summary.outstanding, currencyCode: currency)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
