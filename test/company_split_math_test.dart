import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:expense_tracker/features/company/company_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CompanySplit splitOf(CompanyTxType type, double amount, double percent) {
    return CompanySplit.forType(
      type: type,
      amount: amount,
      mySharePercent: percent,
    );
  }

  test('50/50 income splits the amount in half', () {
    final split = splitOf(CompanyTxType.income, 100000, 50);
    expect(split.mineCents, 5000000);
    expect(split.partnerCents, 5000000);
    expect(split.mineCents + split.partnerCents, CompanySplit.toCents(100000));
  });

  test('60/40 uses the custom share and still sums to the amount', () {
    final split = splitOf(CompanyTxType.sharedExpense, 250.55, 60);
    expect(split.mineCents, 15033);
    expect(split.partnerCents, 10022);
    expect(split.mineCents + split.partnerCents, 25055);
  });

  test('odd amounts round my share and give the remainder to the partner', () {
    final half = splitOf(CompanyTxType.income, 100.01, 50);
    expect(half.mineCents, 5001);
    expect(half.partnerCents, 5000);
    expect(half.mineCents + half.partnerCents, 10001);

    final paisa = splitOf(CompanyTxType.income, 0.01, 50);
    expect(paisa.mineCents, 1);
    expect(paisa.partnerCents, 0);
    expect(paisa.mineCents + paisa.partnerCents, 1);
  });

  test('each transaction type moves the combined pool and the two shares', () {
    const percent = 50.0;
    var book = const CompanyBalance();

    book = book.apply(type: CompanyTxType.income, amount: 100, mySharePercent: percent);
    expect(book.totalCents, 10000);
    expect(book.mineCents, 5000);
    expect(book.partnerCents, 5000);

    book = book.apply(
      type: CompanyTxType.sharedExpense,
      amount: 40,
      mySharePercent: percent,
    );
    expect(book.totalCents, 6000);
    expect(book.mineCents, 3000);
    expect(book.partnerCents, 3000);

    book = book.apply(
      type: CompanyTxType.myWithdrawal,
      amount: 10,
      mySharePercent: percent,
    );
    expect(book.totalCents, 5000);
    expect(book.mineCents, 2000);
    expect(book.partnerCents, 3000);

    book = book.apply(
      type: CompanyTxType.partnerWithdrawal,
      amount: 10,
      mySharePercent: percent,
    );
    expect(book.totalCents, 4000);
    expect(book.mineCents, 2000);
    expect(book.partnerCents, 2000);

    book = book.apply(
      type: CompanyTxType.myContribution,
      amount: 5,
      mySharePercent: percent,
    );
    expect(book.totalCents, 4500);
    expect(book.mineCents, 2500);
    expect(book.partnerCents, 2000);

    book = book.apply(
      type: CompanyTxType.partnerContribution,
      amount: 5,
      mySharePercent: percent,
    );
    expect(book.totalCents, 5000);
    expect(book.mineCents, 2500);
    expect(book.partnerCents, 2500);
  });

  test('withdrawals and contributions ignore the percent split', () {
    final mine = splitOf(CompanyTxType.myWithdrawal, 30, 60);
    expect(mine.mineCents, 3000);
    expect(mine.partnerCents, 0);

    final partner = splitOf(CompanyTxType.partnerContribution, 30, 60);
    expect(partner.mineCents, 0);
    expect(partner.partnerCents, 3000);
  });
}
