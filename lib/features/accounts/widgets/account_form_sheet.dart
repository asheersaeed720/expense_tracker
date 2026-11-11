import 'package:expense_tracker/core/enums/account_type.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef AccountFormResult = ({
  String name,
  AccountType type,
  double initialBalance,
});

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet.create({super.key}) : account = null;

  const AccountFormSheet.edit({super.key, required this.account});

  final Account? account;

  bool get isEdit => account != null;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  AccountType _type = AccountType.cash;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(text: '0');
    _type = widget.account?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    if (widget.isEdit) {
      Navigator.pop(
        context,
        (
          name: name,
          type: widget.account!.type,
          initialBalance: 0.0,
        ),
      );
      return;
    }

    final balance =
        double.tryParse(_balanceController.text.trim().replaceAll(',', '')) ??
            0;

    Navigator.pop(
      context,
      (name: name, type: _type, initialBalance: balance),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isEdit ? 'Edit account' : 'New account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Account name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textInputAction: TextInputAction.done,
            ),
            if (!widget.isEdit) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: AccountType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_labelForType(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Initial balance (PKR)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a balance';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(widget.isEdit ? 'Save' : 'Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _labelForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank';
      case AccountType.wallet:
        return 'Wallet';
    }
  }
}
