import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/icon_name_mapper.dart';
import 'package:expense_tracker/core/widgets/app_empty_state.dart';
import 'package:expense_tracker/core/widgets/app_shimmer_list.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/accounts/widgets/account_form_sheet.dart';
import 'package:expense_tracker/features/accounts/widgets/transfer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    final data = await showModalBottomSheet<AccountFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const AccountFormSheet.create(),
    );

    if (data == null || !context.mounted) return;

    try {
      await ref.read(accountsServiceProvider).createAccount(
            name: data.name,
            type: data.type,
            initialBalance: data.initialBalance,
          );
      if (context.mounted) {
        showAppSnackBar(context, message: 'Account created.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final data = await showModalBottomSheet<AccountFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AccountFormSheet.edit(account: account),
    );

    if (data == null || !context.mounted) return;

    try {
      await ref.read(accountsServiceProvider).updateAccountName(
            accountId: account.id,
            name: data.name,
          );
      if (context.mounted) {
        showAppSnackBar(context, message: 'Account updated.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Delete "${account.name}"? This cannot be undone.',
        ),
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
      await ref.read(accountsServiceProvider).deleteAccount(account.id);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Account deleted.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _openTransferSheet(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) async {
    if (accounts.length < 2) {
      showAppSnackBar(
        context,
        message: 'You need at least two accounts to transfer.',
        isError: true,
      );
      return;
    }

    final data = await showModalBottomSheet<TransferResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TransferSheet(accounts: accounts),
    );

    if (data == null || !context.mounted) return;

    try {
      await ref.read(accountsServiceProvider).transferBetweenAccounts(
            fromAccountId: data.fromId,
            toAccountId: data.toId,
            amount: data.amount,
          );
      if (context.mounted) {
        showAppSnackBar(context, message: 'Transfer completed.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final currency = profile?.currency ?? 'PKR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          TextButton.icon(
            onPressed: accountsAsync.valueOrNull == null
                ? null
                : () => _openTransferSheet(
                      context,
                      ref,
                      accountsAsync.valueOrNull!,
                    ),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Transfer'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-accounts',
        onPressed: () => _openCreateSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: AppShimmerList(),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              subtitle: 'Tap + to add your first account.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    IconNameMapper.accountTypeIcon(account.type.value),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(account.name),
                  subtitle: Text(_typeLabel(account.type.value)),
                  trailing: Text(
                    CurrencyFormatter.format(
                      account.balance,
                      currencyCode: currency,
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  onTap: () => _showAccountActions(context, ref, account),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAccountActions(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit name'),
              onTap: () {
                Navigator.pop(context);
                _openEditSheet(context, ref, account);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete account',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, account);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'wallet':
        return 'Wallet';
      default:
        return type;
    }
  }
}
