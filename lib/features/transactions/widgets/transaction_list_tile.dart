import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/icon_name_mapper.dart';
import 'package:flutter/material.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.item,
    required this.currency,
    required this.onTap,
  });

  final TransactionItem item;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = item.type == TransactionType.expense;
    final amountColor =
        isExpense ? const Color(0xFFF87171) : const Color(0xFF34D399);
    final dotColor = ColorUtils.fromHex(item.categoryColor) ?? amountColor;
    final categoryLabel = item.categoryName ?? 'Uncategorized';

    return ListTile(
      onTap: onTap,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: amountColor.withValues(alpha: 0.12),
            child: Icon(
              IconNameMapper.categoryIcon(item.categoryIcon),
              color: amountColor,
              size: 20,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(categoryLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.description != null && item.description!.trim().isNotEmpty)
            Text(item.description!.trim()),
          if (item.accountName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _AccountBadge(name: item.accountName!),
            ),
        ],
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'}${CurrencyFormatter.format(item.amount, currencyCode: currency)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
