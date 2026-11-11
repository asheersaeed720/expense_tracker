import 'package:expense_tracker/core/models/company_ledger.dart';
import 'package:expense_tracker/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompanySetupResult {
  const CompanySetupResult({
    required this.companyName,
    required this.partnerName,
    required this.mySharePercent,
  });

  final String companyName;
  final String partnerName;
  final double mySharePercent;
}

Future<CompanySetupResult?> showCompanySetupSheet(
  BuildContext context, {
  CompanyLedger? ledger,
}) {
  return showModalBottomSheet<CompanySetupResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => CompanySetupSheet(ledger: ledger),
  );
}

class CompanySetupSheet extends ConsumerStatefulWidget {
  const CompanySetupSheet({super.key, this.ledger});

  final CompanyLedger? ledger;

  @override
  ConsumerState<CompanySetupSheet> createState() => _CompanySetupSheetState();
}

class _CompanySetupSheetState extends ConsumerState<CompanySetupSheet> {
  late final TextEditingController _companyName;
  late final TextEditingController _partnerName;
  late final TextEditingController _share;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ledger = widget.ledger;
    _companyName = TextEditingController(text: ledger?.companyName ?? '');
    _partnerName = TextEditingController(text: ledger?.partnerName ?? '');
    final share = ledger?.mySharePercent ?? 50;
    _share = TextEditingController(text: _shareText(share));
  }

  @override
  void dispose() {
    _companyName.dispose();
    _partnerName.dispose();
    _share.dispose();
    super.dispose();
  }

  double? get _myShare => double.tryParse(_share.text.trim());

  double? get _partnerShare {
    final mine = _myShare;
    if (mine == null) return null;
    final mineCents = (mine * 100).round();
    if (mineCents <= 0 || mineCents >= 10000) return null;
    return (10000 - mineCents) / 100;
  }

  String _shareText(double value) {
    final cents = (value * 100).round();
    if (cents % 100 == 0) return '${cents ~/ 100}';
    return (cents / 100).toStringAsFixed(2);
  }

  void _setShare(double value) {
    final text = _shareText(value);
    _share.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _error = null);
  }

  Future<void> _export() async {
    try {
      await ref.read(dataExportServiceProvider).exportCompanyCsv();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _save() {
    final company = _companyName.text.trim();
    final partner = _partnerName.text.trim();
    final mine = _myShare;
    final mineCents = mine == null ? 0 : (mine * 100).round();
    if (company.isEmpty || partner.isEmpty) {
      setState(() => _error = 'Company name and partner name are required.');
      return;
    }
    if (mineCents <= 0 || mineCents >= 10000) {
      setState(() => _error = 'Your share must be greater than 0 and less than 100.');
      return;
    }

    Navigator.pop(
      context,
      CompanySetupResult(
        companyName: company,
        partnerName: partner,
        mySharePercent: mineCents / 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final partnerShare = _partnerShare;
    final sliderValue = (_myShare ?? 50).clamp(1, 99).toDouble();
    final editing = widget.ledger != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? widget.ledger!.companyName : 'Company / Partner Workspace',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            editing
                ? 'New transactions use the updated split. Past balances stay as they are.'
                : 'This ledger stays separate from your personal accounts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _companyName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Company / Venture Name',
              hintText: 'Tech LLC',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _partnerName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Partner Name',
              hintText: 'Partner Name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _share,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Your Share %',
              helperText: partnerShare == null
                  ? 'Partner share is 100 minus yours'
                  : 'Partner share ${ _shareText(partnerShare) }%',
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          Slider(
            value: sliderValue,
            min: 1,
            max: 99,
            label: '${sliderValue.round()}%',
            onChanged: _setShare,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Save')),
          if (editing) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export company CSV'),
            ),
          ],
        ],
      ),
    );
  }
}
