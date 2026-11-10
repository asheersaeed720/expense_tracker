import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:expense_tracker/features/loans/services/loans_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loansServiceProvider = Provider<LoansService>((ref) => LoansService());

final loansProvider = StreamProvider.family<List<Loan>, LoanType>((ref, type) {
  return ref.watch(loansServiceProvider).watchLoans(type);
});

final loanTabSummaryProvider =
    Provider.family<LoanTabSummary, LoanType>((ref, type) {
  final loans = ref.watch(loansProvider(type)).valueOrNull ?? const [];

  final total = loans.fold<double>(0, (s, l) => s + l.amount);
  final outstanding =
      loans.fold<double>(0, (s, l) => s + l.remainingAmount);

  return LoanTabSummary(totalAmount: total, outstanding: outstanding);
});

typedef LoanDetailParams = ({String loanId});

class LoanDetailNotifier extends AutoDisposeFamilyAsyncNotifier<LoanDetail?, LoanDetailParams> {
  @override
  Future<LoanDetail?> build(LoanDetailParams arg) async {
    final sub = ref
        .read(loansServiceProvider)
        .watchLoanChanges()
        .listen((_) => ref.invalidateSelf());

    ref.onDispose(sub.cancel);

    return ref.read(loansServiceProvider).fetchLoanDetail(arg.loanId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final loanDetailProvider = AsyncNotifierProvider.autoDispose
    .family<LoanDetailNotifier, LoanDetail?, LoanDetailParams>(
  LoanDetailNotifier.new,
);
