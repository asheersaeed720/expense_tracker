import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/features/transactions/models/transaction_filters.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_providers.dart';
import 'package:expense_tracker/features/transactions/utils/transaction_search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kTransactionPageSize = 20;

final transactionFiltersProvider =
    StateProvider<TransactionFilters>((ref) => const TransactionFilters());

class TransactionsListState {
  const TransactionsListState({
    this.items = const [],
    this.totals = const FilteredTotals(income: 0, expense: 0),
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<TransactionItem> items;
  final FilteredTotals totals;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  TransactionsListState copyWith({
    List<TransactionItem>? items,
    FilteredTotals? totals,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return TransactionsListState(
      items: items ?? this.items,
      totals: totals ?? this.totals,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TransactionsListNotifier extends Notifier<TransactionsListState> {
  @override
  TransactionsListState build() {
    ref.listen(transactionFiltersProvider, (previous, next) {
      if (previous != next) {
        _reload();
      }
    });

    final sub = ref
        .read(transactionsServiceProvider)
        .watchTransactionChanges()
        .listen((_) => _reload());

    ref.onDispose(sub.cancel);

    Future.microtask(_reload);
    return const TransactionsListState(isLoading: true);
  }

  Future<void> _reload() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadInitial();
  }

  Future<void> refresh() => _reload();

  Future<void> _loadInitial() async {
    try {
      final service = ref.read(transactionsServiceProvider);
      final filters = ref.read(transactionFiltersProvider);
      final searching = (filters.searchQuery?.trim().isNotEmpty ?? false);
      final pageSize = searching ? 200 : kTransactionPageSize;
      var items = await service.fetchFiltered(
        filters: filters,
        limit: pageSize,
        offset: 0,
      );
      if (searching) {
        items = items
            .where((i) => transactionMatchesSearch(i, filters.searchQuery!))
            .toList();
      }
      final totals = await service.fetchFilteredTotals(filters);

      state = TransactionsListState(
        items: items,
        totals: totals,
        isLoading: false,
        hasMore: !searching && items.length >= kTransactionPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final service = ref.read(transactionsServiceProvider);
      final filters = ref.read(transactionFiltersProvider);
      if (filters.searchQuery?.trim().isNotEmpty ?? false) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }
      final offset = state.items.length;
      final next = await service.fetchFiltered(
        filters: filters,
        limit: kTransactionPageSize,
        offset: offset,
      );

      state = state.copyWith(
        items: [...state.items, ...next],
        isLoadingMore: false,
        hasMore: next.length >= kTransactionPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

final transactionsListProvider =
    NotifierProvider<TransactionsListNotifier, TransactionsListState>(
  TransactionsListNotifier.new,
);
