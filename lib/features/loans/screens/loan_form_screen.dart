import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/loans/providers/loans_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({super.key, this.loanId, this.initialType});

  final String? loanId;
  final LoanType? initialType;

  bool get isEdit => loanId != null;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late LoanType _type;
  String? _accountId;
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isHydrating = false;
  /// Track an old loan without posting opening income/expense to an account.
  bool _existingLoanOnly = false;
  Loan? _existing;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? LoanType.given;
    if (widget.loanId != null) _loadLoan();
  }

  Future<void> _loadLoan() async {
    setState(() => _isHydrating = true);
    final detail = await ref
        .read(loansServiceProvider)
        .fetchLoanDetail(widget.loanId!);
    if (!mounted || detail == null) {
      setState(() => _isHydrating = false);
      return;
    }

    _existing = detail.loan;
    _type = detail.loan.type;
    _nameController.text = detail.loan.personName;
    _phoneController.text = detail.loan.phone ?? '';
    _descriptionController.text = detail.loan.description ?? '';
    _dueDate = detail.loan.dueDate;
    _accountId = detail.loan.accountId;

    setState(() => _isHydrating = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(loansServiceProvider);

      if (widget.isEdit) {
        await service.updateLoan(
          loanId: widget.loanId!,
          personName: _nameController.text,
          phone: _phoneController.text,
          description: _descriptionController.text,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        );
      } else {
        final amount = double.parse(_amountController.text.trim());
        await service.createLoan(
          type: _type,
          personName: _nameController.text,
          amount: amount,
          phone: _phoneController.text,
          accountId: _existingLoanOnly ? null : _accountId,
          description: _descriptionController.text,
          dueDate: _dueDate,
          affectsAccountBalance: !_existingLoanOnly,
        );
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        message: widget.isEdit ? 'Loan updated.' : 'Loan created.',
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

    if (_isHydrating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit loan' : 'Add loan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!widget.isEdit)
              SegmentedButton<LoanType>(
                segments: const [
                  ButtonSegment(value: LoanType.given, label: Text('Given')),
                  ButtonSegment(value: LoanType.taken, label: Text('Taken')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            if (!widget.isEdit) const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Person name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            if (!widget.isEdit) ...[
              const SizedBox(height: 12),
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
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Existing loan'),
                subtitle: const Text(
                  'Money already moved — track what is owed without changing account balance.',
                ),
                value: _existingLoanOnly,
                onChanged: (v) {
                  setState(() {
                    _existingLoanOnly = v;
                    if (v) _accountId = null;
                  });
                },
              ),
              if (!_existingLoanOnly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(
                    labelText: 'Account (optional)',
                    helperText:
                        'Linking an account records the loan as income or expense today.',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No linked account'),
                    ),
                    ...accounts.map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                ),
              ],
            ],
            if (widget.isEdit && _existing != null) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Original amount'),
                subtitle: Text(
                  'PKR ${_existing!.amount.toStringAsFixed(_existing!.amount.truncateToDouble() == _existing!.amount ? 0 : 2)}',
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              textAlignVertical: TextAlignVertical.top,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date (optional)'),
              subtitle: Text(
                _dueDate == null
                    ? 'Not set'
                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dueDate != null)
                    IconButton(
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ],
              ),
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
                  : Text(widget.isEdit ? 'Save changes' : 'Save loan'),
            ),
          ],
        ),
      ),
    );
  }
}
