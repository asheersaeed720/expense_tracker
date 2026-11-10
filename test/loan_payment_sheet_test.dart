import 'package:expense_tracker/core/enums/account_type.dart';
import 'package:expense_tracker/core/enums/loan_status.dart';
import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:expense_tracker/features/loans/widgets/loan_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('payment sheet blocks an amount above the remaining balance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final loan = Loan(
      id: 'loan-1',
      userId: 'user-1',
      personName: 'Ali',
      type: LoanType.given,
      amount: 1000,
      remainingAmount: 400,
      status: LoanStatus.partial,
    );
    const account = Account(
      id: 'acc-1',
      userId: 'user-1',
      name: 'Cash',
      type: AccountType.cash,
      balance: 5000,
      isDefault: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoanPaymentSheet(loan: loan, accounts: const [account]),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '401');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Cannot exceed remaining amount'), findsOneWidget);
  });
}
