import 'package:expense_tracker/core/enums/company_tx_type.dart';

enum CompanyDatePreset { thisMonth, lastMonth, custom }

enum CompanyTxTypeFilter { all, income, sharedExpense, withdrawals, contributions }

class CompanyTxFilters {
  const CompanyTxFilters({
    this.datePreset = CompanyDatePreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.typeFilter = CompanyTxTypeFilter.all,
    this.searchQuery,
  });

  final CompanyDatePreset datePreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final CompanyTxTypeFilter typeFilter;
  final String? searchQuery;

  CompanyTxFilters copyWith({
    CompanyDatePreset? datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    CompanyTxTypeFilter? typeFilter,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return CompanyTxFilters(
      datePreset: datePreset ?? this.datePreset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      typeFilter: typeFilter ?? this.typeFilter,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  (DateTime start, DateTime end) resolveRange() {
    final now = DateTime.now();
    switch (datePreset) {
      case CompanyDatePreset.thisMonth:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
      case CompanyDatePreset.lastMonth:
        return (DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0));
      case CompanyDatePreset.custom:
        return (
          customStart ?? DateTime(now.year, now.month, 1),
          customEnd ?? now,
        );
    }
  }

  bool matchesType(CompanyTxType type) {
    switch (typeFilter) {
      case CompanyTxTypeFilter.all:
        return true;
      case CompanyTxTypeFilter.income:
        return type == CompanyTxType.income;
      case CompanyTxTypeFilter.sharedExpense:
        return type == CompanyTxType.sharedExpense;
      case CompanyTxTypeFilter.withdrawals:
        return type == CompanyTxType.myWithdrawal ||
            type == CompanyTxType.partnerWithdrawal;
      case CompanyTxTypeFilter.contributions:
        return type == CompanyTxType.myContribution ||
            type == CompanyTxType.partnerContribution;
    }
  }
}
