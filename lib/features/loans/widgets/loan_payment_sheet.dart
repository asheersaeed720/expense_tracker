import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef LoanPaymentResult = ({
  double amount,
  String accountId,
  DateTime paidAt,
  String? note,
});

class LoanPaymentSheet extends StatefulWidget {
  const LoanPaymentSheet({
    super.key,
    required this.loan,
    required this.accounts,
    this.initialAmount,
    this.title = 'Record payment',
  });

  final Loan loan;
  final List<Account> accounts;
  final double? initialAmount;
  final String title;

  @override
  State<LoanPaymentSheet> createState() => _LoanPaymentSheetState();
}

class _LoanPaymentSheetState extends State<LoanPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();
  String? _accountId;
  DateTime _paidAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount ?? widget.loan.remainingAmount;
    _amountController = TextEditingController(
      text: initial.toStringAsFixed(
        initial.truncateToDouble() == initial ? 0 : 2,
      ),
    );
    if (widget.accounts.isNotEmpty) {
      _accountId = widget.accounts.firstWhere(
        (a) => a.isDefault,
        orElse: () => widget.accounts.first,
      ).id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_accountId == null) return;

    final amount = double.parse(_amountController.text.trim());
    Navigator.pop(
      context,
      (
        amount: amount,
        accountId: _accountId!,
        paidAt: _paidAt,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxPay = widget.loan.remainingAmount;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Remaining: PKR ${maxPay.toStringAsFixed(maxPay.truncateToDouble() == maxPay ? 0 : 2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(labelText: 'Amount (PKR)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) {
                  return 'Amount must be greater than zero';
                }
                if (amount > maxPay + 0.001) {
                  return 'Cannot exceed remaining amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_accountId),
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Account'),
              items: widget.accounts
                  .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
              validator: (v) => v == null ? 'Select account' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                '${_paidAt.day.toString().padLeft(2, '0')}/'
                '${_paidAt.month.toString().padLeft(2, '0')}/'
                '${_paidAt.year}',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _noteController,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
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
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
