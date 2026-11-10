import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/icon_name_mapper.dart';
import 'package:flutter/material.dart';

class AccountSummaryCarousel extends StatelessWidget {
  const AccountSummaryCarousel({
    super.key,
    required this.accounts,
    this.currency = 'PKR',
  });

  final List<Account> accounts;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No accounts yet')),
      );
    }

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return _AccountChip(
            account: account,
            currency: currency,
          );
        },
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.account,
    required this.currency,
  });

  final Account account;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            IconNameMapper.accountTypeIcon(account.type.value),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          Text(
            CurrencyFormatter.format(account.balance, currencyCode: currency),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
