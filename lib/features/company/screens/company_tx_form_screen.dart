import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/company/company_categories.dart';
import 'package:expense_tracker/features/company/company_split.dart';
import 'package:expense_tracker/features/company/providers/company_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanyTxFormScreen extends ConsumerStatefulWidget {
  const CompanyTxFormScreen({
    super.key,
    this.transactionId,
    this.initialType = CompanyTxType.income,
  });

  final String? transactionId;
  final CompanyTxType initialType;

  bool get isEdit => transactionId != null;

  @override
  ConsumerState<CompanyTxFormScreen> createState() => _CompanyTxFormScreenState();
}

class _CompanyTxFormScreenState extends ConsumerState<CompanyTxFormScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  CompanyTxType _type = CompanyTxType.income;
  String _category = 'Client Payment';
  DateTime _date = DateTime.now();
  bool _linkPersonal = false;
  String? _personalAccountId;
  String? _existingLinkedId;
  bool _loading = false;
  bool _hydrating = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = defaultCompanyCategory(_type);
    _amountController.addListener(_onAmountChanged);
    if (widget.transactionId != null) {
      _hydrating = true;
      _load();
    }
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final item = await ref.read(companyServiceProvider).fetchById(widget.transactionId!);
    if (!mounted) return;
    if (item != null) {
      _type = item.type;
      _category = item.category;
      _date = item.date;
      _descriptionController.text = item.description ?? '';
      _existingLinkedId = item.linkedPersonalTxId;
      _linkPersonal = item.linkedPersonalTxId != null;
      _amountController.text = _amountText(item.amount);
      if (item.linkedPersonalTxId != null) {
        _personalAccountId = await ref
            .read(companyServiceProvider)
            .fetchPersonalAccountId(item.linkedPersonalTxId!);
      }
    }
    if (mounted) setState(() => _hydrating = false);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _amountText(double amount) {
    final cents = CompanySplit.toCents(amount);
    if (cents % 100 == 0) return '${cents ~/ 100}';
    return CompanySplit.centsToSql(cents);
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

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
    final ledger = ref.read(companyLedgerProvider).valueOrNull;
    final amount = _amount;
    if (ledger == null) {
      showAppSnackBar(context, message: 'Company ledger is not set up.', isError: true);
      return;
    }
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, message: 'Amount must be greater than zero.', isError: true);
      return;
    }
    if (_linkPersonal && _type.canLinkPersonalAccount && _personalAccountId == null) {
      showAppSnackBar(context, message: 'Select a personal account.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(companyServiceProvider).saveTransaction(
            id: widget.transactionId,
            ledgerId: ledger.id,
            companyName: ledger.companyName,
            type: _type,
            amount: amount,
            mySharePercent: ledger.mySharePercent,
            category: _category,
            date: _date,
            description: _descriptionController.text,
            linkPersonal: _linkPersonal,
            personalAccountId: _personalAccountId,
            existingLinkedPersonalTxId: _existingLinkedId,
          );
      refreshCompanyViews(ref);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: widget.isEdit ? 'Company transaction updated.' : 'Company transaction saved.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppSnackBar(context, message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = ref.watch(companyLedgerProvider).valueOrNull;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';
    final amount = _amount;
    final split = ledger == null || amount == null || amount <= 0
        ? null
        : CompanySplit.forType(
            type: _type,
            amount: amount,
            mySharePercent: ledger.mySharePercent,
          );

    if (_hydrating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit company transaction' : 'Company transaction'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in CompanyTxType.values)
                ChoiceChip(
                  label: Text(type.label),
                  selected: _type == type,
                  onSelected: (_) {
                    setState(() {
                      _type = type;
                      _category = defaultCompanyCategory(type);
                      if (!type.canLinkPersonalAccount) _linkPersonal = false;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Amount', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge),
          TextField(
            controller: _amountController,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '$currency ',
              prefixStyle: Theme.of(context).textTheme.headlineSmall,
              border: InputBorder.none,
              hintText: '0',
            ),
          ),
          const SizedBox(height: 8),
          _SplitPreview(
            currency: currency,
            partnerName: ledger?.partnerName ?? 'Partner',
            type: _type,
            mine: split?.mine,
            partner: split?.partner,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(_category),
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final category in companyCategories)
                DropdownMenuItem(value: category.name, child: Text(category.name)),
              if (!companyCategories.any((c) => c.name == _category))
                DropdownMenuItem(value: _category, child: Text(_category)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormatter.transactionDate(_date)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
            minLines: 2,
            maxLines: 4,
          ),
          if (_type.canLinkPersonalAccount) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _type == CompanyTxType.myWithdrawal
                    ? 'Deposit into my Personal Account?'
                    : 'Deduct from my Personal Account?',
              ),
              value: _linkPersonal,
              onChanged: (value) {
                setState(() {
                  _linkPersonal = value;
                  if (value && _personalAccountId == null && accounts.isNotEmpty) {
                    final preferred = accounts.where((a) => a.isDefault);
                    _personalAccountId =
                        (preferred.isEmpty ? accounts.first : preferred.first).id;
                  }
                });
              },
            ),
            if (_linkPersonal)
              DropdownButtonFormField<String>(
                key: ValueKey(_personalAccountId),
                initialValue: accounts.any((a) => a.id == _personalAccountId)
                    ? _personalAccountId
                    : null,
                decoration: const InputDecoration(labelText: 'Personal account'),
                items: [
                  for (final account in accounts)
                    DropdownMenuItem(value: account.id, child: Text(account.name)),
                ],
                onChanged: (value) => setState(() => _personalAccountId = value),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _SplitPreview extends StatelessWidget {
  const _SplitPreview({
    required this.currency,
    required this.partnerName,
    required this.type,
    required this.mine,
    required this.partner,
  });

  final String currency;
  final String partnerName;
  final CompanyTxType type;
  final double? mine;
  final double? partner;

  @override
  Widget build(BuildContext context) {
    final sign = type == CompanyTxType.income ||
            type == CompanyTxType.myContribution ||
            type == CompanyTxType.partnerContribution
        ? '+'
        : '-';

    String line(double? amount) {
      if (amount == null) return '—';
      return '$sign${CurrencyFormatter.format(amount.abs(), currencyCode: currency)}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Split preview', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('My Share  ${line(mine)}'),
            const SizedBox(height: 4),
            Text('$partnerName  ${line(partner)}'),
          ],
        ),
      ),
    );
  }
}
