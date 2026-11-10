import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/models/category.dart';
import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/core/utils/icon_name_mapper.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/categories/providers/categories_providers.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.transactionId});

  final String? transactionId;

  bool get isEdit => transactionId != null;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _accountId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool _isHydrating = false;
  bool _defaultAccountApplied = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isHydrating = true);
    final item = await ref
        .read(transactionsServiceProvider)
        .fetchById(widget.transactionId!);
    if (!mounted || item == null) {
      setState(() => _isHydrating = false);
      return;
    }
    _applyTransaction(item);
    setState(() => _isHydrating = false);
  }

  void _applyTransaction(TransactionItem item) {
    _type = item.type;
    _accountId = item.accountId;
    _categoryId = item.categoryId;
    _date = item.date;
    _amountController.text = item.amount.toStringAsFixed(
      item.amount.truncateToDouble() == item.amount ? 0 : 2,
    );
    _descriptionController.text = item.description ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Category> _categoriesForType() {
    return _type == TransactionType.expense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      _categoryId = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_accountId == null) {
      showAppSnackBar(context, message: 'Select an account', isError: true);
      return;
    }
    if (_categoryId == null) {
      showAppSnackBar(context, message: 'Select a category', isError: true);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final service = ref.read(transactionsServiceProvider);

    setState(() => _isLoading = true);
    try {
      final description = _descriptionController.text.trim();
      if (widget.isEdit) {
        await service.updateTransaction(
          id: widget.transactionId!,
          type: _type,
          amount: amount,
          accountId: _accountId!,
          categoryId: _categoryId!,
          date: _date,
          description: description,
        );
      } else {
        await service.createTransaction(
          type: _type,
          amount: amount,
          accountId: _accountId!,
          categoryId: _categoryId!,
          date: _date,
          description: description,
        );
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        message: widget.isEdit ? 'Transaction updated.' : 'Transaction saved.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories = _categoriesForType();
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';

    if (!_defaultAccountApplied &&
        !widget.isEdit &&
        _accountId == null &&
        accounts.isNotEmpty) {
      _defaultAccountApplied = true;
      final defaultAccount = accounts.firstWhere(
        (a) => a.isDefault,
        orElse: () => accounts.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _accountId = defaultAccount.id);
      });
    }

    if (_isHydrating) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit transaction' : 'Add transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => _onTypeChanged(s.first),
            ),
            const SizedBox(height: 24),
            Text(
              'Amount',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              decoration: InputDecoration(
                prefixText: '$currency ',
                prefixStyle: Theme.of(context).textTheme.headlineSmall,
                border: InputBorder.none,
                hintText: '0',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final parsed = double.tryParse(v);
                if (parsed == null || parsed <= 0) {
                  return 'Amount must be greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_accountId),
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Account'),
              items: accounts
                  .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _CategoryGrid(
              categories: categories,
              selectedId: _categoryId,
              onSelected: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_formatDate(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(widget.isEdit ? 'Save changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('No categories available.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final selected = category.id == selectedId;
        final color = ColorUtils.fromHex(category.color) ??
            Theme.of(context).colorScheme.primary;

        return ChoiceChip(
          showCheckmark: false,
          selected: selected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconNameMapper.categoryIcon(category.icon),
                size: 18,
                color: selected ? Theme.of(context).colorScheme.onPrimary : color,
              ),
              const SizedBox(width: 6),
              Text(category.name),
            ],
          ),
          selectedColor: color,
          onSelected: (_) => onSelected(category.id),
        );
      }).toList(),
    );
  }
}
