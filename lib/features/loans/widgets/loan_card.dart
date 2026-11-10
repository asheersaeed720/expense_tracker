import 'package:expense_tracker/core/models/loan.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/loans/widgets/loan_status_badge.dart';
import 'package:flutter/material.dart';

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    required this.currency,
    required this.onTap,
  });

  final Loan loan;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dueText = loan.dueDate != null
        ? 'Due ${DateFormatter.transactionDate(loan.dueDate!)}'
        : null;
    final dueColor = loan.isOverdue
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.personName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (loan.phone != null && loan.phone!.trim().isNotEmpty)
                          Text(
                            loan.phone!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.65),
                                ),
                          ),
                      ],
                    ),
                  ),
                  LoanStatusBadge(status: loan.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Original: ${CurrencyFormatter.format(loan.amount, currencyCode: currency)}',
              ),
              Text(
                'Remaining: ${CurrencyFormatter.format(loan.remainingAmount, currencyCode: currency)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (dueText != null) ...[
                const SizedBox(height: 4),
                Text(dueText, style: TextStyle(color: dueColor, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: loan.repaidFraction,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
