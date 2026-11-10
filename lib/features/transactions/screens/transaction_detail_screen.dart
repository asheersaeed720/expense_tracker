import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_name_mapper.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';

    return FutureBuilder<TransactionItem?>(
      future: ref.read(transactionsServiceProvider).fetchById(transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Transaction not found.')),
          );
        }

        final isExpense = item.type == TransactionType.expense;
        final amountColor =
            isExpense ? const Color(0xFFF87171) : const Color(0xFF34D399);

        return Scaffold(
          appBar: AppBar(title: const Text('Transaction')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          IconNameMapper.categoryIcon(item.categoryIcon),
                          size: 40,
                          color: amountColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.categoryName ?? 'Uncategorized',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${isExpense ? '-' : '+'}${CurrencyFormatter.format(item.amount, currencyCode: currency)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(DateFormatter.headerDate(item.date)),
                        if (item.accountName != null) ...[
                          const SizedBox(height: 4),
                          Text('Account: ${item.accountName}'),
                        ],
                        if (item.description != null &&
                            item.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(item.description!.trim()),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      RoutePaths.transactionFormEditPath(transactionId),
                    );
                    if (updated == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will update the account balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(transactionsServiceProvider).deleteTransaction(transactionId);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Transaction deleted.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }
}
