import 'package:expense_tracker/core/models/monthly_stats.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class MonthlyStatsRow extends StatelessWidget {
  const MonthlyStatsRow({
    super.key,
    required this.stats,
    this.currency = 'PKR',
  });

  final MonthlyStats stats;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Income',
            amount: stats.income,
            currency: currency,
            color: const Color(0xFF34D399),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Expense',
            amount: stats.expense,
            currency: currency,
            color: const Color(0xFFF87171),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount, currencyCode: currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
