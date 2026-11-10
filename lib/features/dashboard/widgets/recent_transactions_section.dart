import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_name_mapper.dart';
import 'package:flutter/material.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onSeeAll,
    this.currency = 'PKR',
  });

  final List<TransactionItem> transactions;
  final VoidCallback onSeeAll;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Recent transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            TextButton(onPressed: onSeeAll, child: const Text('See All')),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No transactions yet. Tap + on the Transactions tab to add one.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
              ),
            ),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _TransactionTile(
                  item: transactions[index],
                  currency: currency,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.currency,
  });

  final TransactionItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isExpense = item.type == TransactionType.expense;
    final amountColor =
        isExpense ? const Color(0xFFF87171) : const Color(0xFF34D399);
    final prefix = isExpense ? '-' : '+';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withValues(alpha: 0.15),
        child: Icon(
          IconNameMapper.categoryIcon(item.categoryIcon),
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(item.title),
      subtitle: Text(
        [
          if (item.accountName != null) item.accountName,
          DateFormatter.transactionDate(item.date),
        ].whereType<String>().join(' · '),
      ),
      trailing: Text(
        '$prefix${CurrencyFormatter.format(item.amount, currencyCode: currency)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
