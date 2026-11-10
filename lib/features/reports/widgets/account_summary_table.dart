import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/reports/models/report_models.dart';
import 'package:flutter/material.dart';

class AccountSummaryTable extends StatelessWidget {
  const AccountSummaryTable({
    super.key,
    required this.rows,
    this.currency = 'PKR',
  });

  final List<AccountPeriodSummary> rows;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No accounts to summarize.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: Theme.of(context).textTheme.labelLarge,
        columns: const [
          DataColumn(label: Text('Account')),
          DataColumn(label: Text('Opening')),
          DataColumn(label: Text('Income')),
          DataColumn(label: Text('Expense')),
          DataColumn(label: Text('Closing')),
        ],
        rows: rows
            .map(
              (r) => DataRow(
                cells: [
                  DataCell(Text(r.accountName)),
                  DataCell(Text(_fmt(r.openingBalance))),
                  DataCell(Text(_fmt(r.income))),
                  DataCell(Text(_fmt(r.expense))),
                  DataCell(Text(_fmt(r.closingBalance))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  String _fmt(double amount) =>
      CurrencyFormatter.format(amount, currencyCode: currency);
}
