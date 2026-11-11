import 'package:expense_tracker/core/enums/company_tx_type.dart';

/// Money math in integer cents so a split always adds back to the amount.
class CompanySplit {
  const CompanySplit({
    required this.mineCents,
    required this.partnerCents,
  });

  final int mineCents;
  final int partnerCents;

  double get mine => mineCents / 100;
  double get partner => partnerCents / 100;

  static int toCents(double amount) => (amount * 100).round();

  static String centsToSql(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final text = '${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
    return negative ? '-$text' : text;
  }

  /// [mySharePercent] is the user's share, e.g. 60 for 60%.
  static CompanySplit forType({
    required CompanyTxType type,
    required double amount,
    required double mySharePercent,
  }) {
    return forCents(
      type: type,
      amountCents: toCents(amount),
      mySharePercent: mySharePercent,
    );
  }

  static CompanySplit forCents({
    required CompanyTxType type,
    required int amountCents,
    required double mySharePercent,
  }) {
    if (amountCents <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    switch (type) {
      case CompanyTxType.myWithdrawal:
      case CompanyTxType.myContribution:
        return CompanySplit(mineCents: amountCents, partnerCents: 0);
      case CompanyTxType.partnerWithdrawal:
      case CompanyTxType.partnerContribution:
        return CompanySplit(mineCents: 0, partnerCents: amountCents);
      case CompanyTxType.income:
      case CompanyTxType.sharedExpense:
        final basis = (mySharePercent * 100).round();
        if (basis <= 0 || basis >= 10000) {
          throw ArgumentError('Share must be between 0 and 100.');
        }
        final mine = ((amountCents * basis) / 10000).round();
        return CompanySplit(mineCents: mine, partnerCents: amountCents - mine);
    }
  }
}

class CompanyBalance {
  const CompanyBalance({
    this.totalCents = 0,
    this.mineCents = 0,
    this.partnerCents = 0,
  });

  final int totalCents;
  final int mineCents;
  final int partnerCents;

  double get total => totalCents / 100;
  double get mine => mineCents / 100;
  double get partner => partnerCents / 100;

  CompanyBalance apply({
    required CompanyTxType type,
    required double amount,
    required double mySharePercent,
  }) {
    final amountCents = CompanySplit.toCents(amount);
    final split = CompanySplit.forCents(
      type: type,
      amountCents: amountCents,
      mySharePercent: mySharePercent,
    );
    final effect = effectOf(
      type: type,
      amountCents: amountCents,
      split: split,
    );
    return CompanyBalance(
      totalCents: totalCents + effect.totalCents,
      mineCents: mineCents + effect.mineCents,
      partnerCents: partnerCents + effect.partnerCents,
    );
  }

  static CompanyBalance effectOf({
    required CompanyTxType type,
    required int amountCents,
    required CompanySplit split,
  }) {
    switch (type) {
      case CompanyTxType.income:
        return CompanyBalance(
          totalCents: amountCents,
          mineCents: split.mineCents,
          partnerCents: split.partnerCents,
        );
      case CompanyTxType.sharedExpense:
        return CompanyBalance(
          totalCents: -amountCents,
          mineCents: -split.mineCents,
          partnerCents: -split.partnerCents,
        );
      case CompanyTxType.myWithdrawal:
        return CompanyBalance(totalCents: -amountCents, mineCents: -amountCents);
      case CompanyTxType.partnerWithdrawal:
        return CompanyBalance(
          totalCents: -amountCents,
          partnerCents: -amountCents,
        );
      case CompanyTxType.myContribution:
        return CompanyBalance(totalCents: amountCents, mineCents: amountCents);
      case CompanyTxType.partnerContribution:
        return CompanyBalance(
          totalCents: amountCents,
          partnerCents: amountCents,
        );
    }
  }
}
