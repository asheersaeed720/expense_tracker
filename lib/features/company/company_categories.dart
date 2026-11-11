import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:flutter/material.dart';

class CompanyCategory {
  const CompanyCategory(this.name, this.icon);

  final String name;
  final IconData icon;
}

const companyCategories = <CompanyCategory>[
  CompanyCategory('Client Payment', Icons.payments_outlined),
  CompanyCategory('Project Milestone', Icons.flag_outlined),
  CompanyCategory('Retainer', Icons.autorenew),
  CompanyCategory('Server & SaaS', Icons.cloud_outlined),
  CompanyCategory('Marketing', Icons.campaign_outlined),
  CompanyCategory('Contractor / Payroll', Icons.groups_outlined),
  CompanyCategory('Office / Utilities', Icons.apartment_outlined),
  CompanyCategory('Tax / Legal', Icons.gavel_outlined),
  CompanyCategory('Partner Payout', Icons.account_balance_wallet_outlined),
  CompanyCategory('Capital Injection', Icons.savings_outlined),
  CompanyCategory('Other', Icons.more_horiz),
];

IconData companyCategoryIcon(String name) {
  for (final category in companyCategories) {
    if (category.name == name) return category.icon;
  }
  return Icons.more_horiz;
}

String defaultCompanyCategory(CompanyTxType type) {
  switch (type) {
    case CompanyTxType.income:
      return 'Client Payment';
    case CompanyTxType.sharedExpense:
      return 'Other';
    case CompanyTxType.myWithdrawal:
    case CompanyTxType.partnerWithdrawal:
      return 'Partner Payout';
    case CompanyTxType.myContribution:
    case CompanyTxType.partnerContribution:
      return 'Capital Injection';
  }
}
