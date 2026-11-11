enum CompanyTxType {
  income('income', 'Income'),
  sharedExpense('shared_expense', 'Shared Expense'),
  myWithdrawal('my_withdrawal', 'My Withdrawal'),
  partnerWithdrawal('partner_withdrawal', 'Partner Withdrawal'),
  myContribution('my_contribution', 'My Contribution'),
  partnerContribution('partner_contribution', 'Partner Contribution');

  const CompanyTxType(this.value, this.label);

  final String value;
  final String label;

  bool get isPoolSplit =>
      this == CompanyTxType.income || this == CompanyTxType.sharedExpense;

  bool get increasesPool =>
      this == CompanyTxType.income ||
      this == CompanyTxType.myContribution ||
      this == CompanyTxType.partnerContribution;

  bool get canLinkPersonalAccount =>
      this == CompanyTxType.myWithdrawal || this == CompanyTxType.myContribution;

  static CompanyTxType? fromValue(String? raw) {
    if (raw == null) return null;
    for (final type in CompanyTxType.values) {
      if (type.value == raw) return type;
    }
    return null;
  }
}
