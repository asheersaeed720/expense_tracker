import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/loans/providers/loans_providers.dart';
import 'package:expense_tracker/features/loans/widgets/loan_card.dart';
import 'package:expense_tracker/features/loans/widgets/loan_empty_state.dart';
import 'package:expense_tracker/features/loans/widgets/loan_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAdd(LoanType type) async {
    final created = await context.push<bool>(
      '${RoutePaths.loanForm}?type=${type.value}',
    );
    if (created == true && mounted) {
      ref.invalidate(loansProvider(LoanType.given));
      ref.invalidate(loansProvider(LoanType.taken));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Given'),
            Tab(text: 'Taken'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-loans',
        onPressed: () {
          final type =
              _tabController.index == 0 ? LoanType.given : LoanType.taken;
          _openAdd(type);
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LoansTab(type: LoanType.given, currency: currency),
          _LoansTab(type: LoanType.taken, currency: currency),
        ],
      ),
    );
  }
}

class _LoansTab extends ConsumerWidget {
  const _LoansTab({required this.type, required this.currency});

  final LoanType type;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider(type));
    final summary = ref.watch(loanTabSummaryProvider(type));

    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (loans) {
        if (loans.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              LoanSummaryCard(type: type, summary: summary, currency: currency),
              const SizedBox(height: 24),
              LoanEmptyState(
                message: type == LoanType.given
                    ? 'You have not lent money to anyone yet.'
                    : 'You have not borrowed money from anyone yet.',
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(loansProvider(type));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: loans.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LoanSummaryCard(
                    type: type,
                    summary: summary,
                    currency: currency,
                  ),
                );
              }

              final loan = loans[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LoanCard(
                  loan: loan,
                  currency: currency,
                  onTap: () => context.push(RoutePaths.loanDetailPath(loan.id)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
