import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/features/transactions/models/transaction_filters.dart';
import 'package:flutter/material.dart';

class TransactionFiltersBar extends StatelessWidget {
  const TransactionFiltersBar({
    super.key,
    required this.filters,
    required this.accounts,
    required this.onChanged,
  });

  final TransactionFilters filters;
  final List<Account> accounts;
  final ValueChanged<TransactionFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'This month',
                selected: filters.datePreset == TransactionDatePreset.thisMonth,
                onTap: () => onChanged(
                  filters.copyWith(datePreset: TransactionDatePreset.thisMonth),
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Last month',
                selected: filters.datePreset == TransactionDatePreset.lastMonth,
                onTap: () => onChanged(
                  filters.copyWith(datePreset: TransactionDatePreset.lastMonth),
                ),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Custom',
                selected: filters.datePreset == TransactionDatePreset.custom,
                onTap: () => _pickCustomRange(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All types',
                selected: filters.type == null,
                onTap: () => onChanged(filters.copyWith(clearType: true)),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Expense',
                selected: filters.type == TransactionType.expense,
                onTap: () => onChanged(filters.copyWith(type: TransactionType.expense)),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Income',
                selected: filters.type == TransactionType.income,
                onTap: () => onChanged(filters.copyWith(type: TransactionType.income)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: filters.accountId,
          decoration: const InputDecoration(
            labelText: 'Account',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All accounts'),
            ),
            ...accounts.map(
              (a) => DropdownMenuItem<String?>(
                value: a.id,
                child: Text(a.name),
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              onChanged(filters.copyWith(clearAccount: true));
            } else {
              onChanged(filters.copyWith(accountId: value));
            }
          },
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = filters.customStart ?? DateTime(now.year, now.month, 1);
    final initialEnd = filters.customEnd ?? now;

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (range == null) return;

    onChanged(
      filters.copyWith(
        datePreset: TransactionDatePreset.custom,
        customStart: range.start,
        customEnd: range.end,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}
