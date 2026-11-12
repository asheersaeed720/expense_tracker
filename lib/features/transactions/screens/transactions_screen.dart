import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/utils/app_haptics.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/widgets/app_empty_state.dart';
import 'package:expense_tracker/core/widgets/app_shimmer_list.dart';
import 'package:expense_tracker/core/widgets/scaffold_with_fab.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_list_provider.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_providers.dart';
import 'package:expense_tracker/features/transactions/utils/transaction_grouper.dart';
import 'package:expense_tracker/features/transactions/widgets/transaction_filters_bar.dart';
import 'package:expense_tracker/features/transactions/widgets/transaction_list_tile.dart';
import 'package:expense_tracker/features/transactions/widgets/transaction_summary_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 200) {
      ref.read(transactionsListProvider.notifier).loadMore();
    }
  }

  Future<void> _openAdd() async {
    await AppHaptics.light();
    if (!mounted) return;
    final created = await context.push<bool>(RoutePaths.transactionForm);
    if (created == true && mounted) {
      await ref.read(transactionsListProvider.notifier).refresh();
    }
  }

  Future<bool> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return false;

    await AppHaptics.medium();

    try {
      await ref.read(transactionsServiceProvider).deleteTransaction(id);
      if (!mounted) return false;
      showAppSnackBar(context, message: 'Transaction deleted.');
      await ref.read(transactionsListProvider.notifier).refresh();
      return true;
    } catch (e) {
      if (!mounted) return false;
      showAppSnackBar(context, message: e.toString(), isError: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(transactionsListProvider);
    final filters = ref.watch(transactionFiltersProvider);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';
    final groups = TransactionGrouper.groupByDay(listState.items);

    return ScaffoldWithFab(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-transactions',
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsListProvider.notifier).refresh(),
        child: listState.isLoading && listState.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [AppShimmerList()],
              )
            : CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search description, category, amount…',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          ref.read(transactionFiltersProvider.notifier).state = filters.copyWith(
                            searchQuery: value.trim().isEmpty ? null : value.trim(),
                            clearSearch: value.trim().isEmpty,
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TransactionFiltersBar(
                        filters: filters,
                        accounts: accounts,
                        onChanged: (next) =>
                            ref.read(transactionFiltersProvider.notifier).state = next,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TransactionSummaryHeader(totals: listState.totals, currency: currency),
                    ),
                  ),
                  if (listState.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No transactions found',
                        subtitle: filters.searchQuery?.isNotEmpty == true
                            ? 'Try another search or adjust filters.'
                            : 'Tap + to add your first transaction.',
                      ),
                    )
                  else
                    ...groups.expand((group) sync* {
                      yield SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            group.heading,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                      yield SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = group.items[index];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Theme.of(context).colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) => _confirmDelete(item.id),
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: TransactionListTile(
                                item: item,
                                currency: currency,
                                onTap: () =>
                                    context.push(RoutePaths.transactionDetailPath(item.id)),
                              ),
                            ),
                          );
                        }, childCount: group.items.length),
                      );
                    }),
                  if (listState.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
      ),
    );
  }
}
