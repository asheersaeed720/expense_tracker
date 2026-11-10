import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/enums/loan_status.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/loans/providers/loans_providers.dart';
import 'package:expense_tracker/features/loans/widgets/loan_payment_sheet.dart';
import 'package:expense_tracker/features/loans/widgets/loan_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(loanDetailProvider((loanId: loanId)));
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <Account>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan detail'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final updated = await context.push<bool>(
                  RoutePaths.loanFormEditPath(loanId),
                );
                if (updated == true) {
                  ref.invalidate(loanDetailProvider((loanId: loanId)));
                }
              } else if (value == 'delete') {
                await _confirmDelete(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Loan not found.'));
          }

          final loan = detail.loan;
          final canPay = loan.remainingAmount > 0 && loan.status != LoanStatus.settled;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(loanDetailProvider((loanId: loanId)));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loan.personName,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            LoanStatusBadge(status: loan.status),
                          ],
                        ),
                        if (loan.phone != null && loan.phone!.trim().isNotEmpty)
                          Text(loan.phone!),
                        const SizedBox(height: 12),
                        Text(
                          'Original: ${CurrencyFormatter.format(loan.amount, currencyCode: currency)}',
                        ),
                        Text(
                          'Remaining: ${CurrencyFormatter.format(loan.remainingAmount, currencyCode: currency)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (loan.dueDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Due: ${DateFormatter.headerDate(loan.dueDate!)}',
                            style: TextStyle(
                              color: loan.isOverdue
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                        ],
                        if (loan.description != null &&
                            loan.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(loan.description!.trim()),
                        ],
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: loan.repaidFraction),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (detail.payments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No payments recorded yet.'),
                    ),
                  )
                else
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detail.payments.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final payment = detail.payments[index];
                        return ListTile(
                          title: Text(
                            CurrencyFormatter.format(
                              payment.amount,
                              currencyCode: currency,
                            ),
                          ),
                          subtitle: Text(
                            [
                              DateFormatter.transactionDate(payment.paidAt),
                              if (payment.note != null) payment.note,
                            ].whereType<String>().join(' · '),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                if (canPay) ...[
                  FilledButton.icon(
                    onPressed: accounts.isEmpty
                        ? null
                        : () => _recordPayment(context, ref, loan, accounts, false),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Record payment'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: accounts.isEmpty
                        ? null
                        : () => _recordPayment(context, ref, loan, accounts, true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Settle in full'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    Loan loan,
    List<Account> accounts,
    bool settle,
  ) async {
    final result = await showModalBottomSheet<LoanPaymentResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => LoanPaymentSheet(
        loan: loan,
        accounts: accounts,
        initialAmount: settle ? loan.remainingAmount : null,
        title: settle ? 'Settle loan' : 'Record payment',
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      final service = ref.read(loansServiceProvider);
      if (settle) {
        await service.settleLoan(
          loan: loan,
          accountId: result.accountId,
          note: result.note,
        );
      } else {
        await service.recordPayment(
          loan: loan,
          amount: result.amount,
          accountId: result.accountId,
          paidAt: result.paidAt,
          note: result.note,
        );
      }

      if (context.mounted) {
        showAppSnackBar(context, message: settle ? 'Loan settled.' : 'Payment recorded.');
        ref.invalidate(loanDetailProvider((loanId: loanId)));
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete loan?'),
        content: const Text('Payment history will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(loansServiceProvider).deleteLoan(loanId);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Loan deleted.');
        context.pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }
}
