import 'package:expense_tracker/core/providers/supabase_realtime_auth_binding.dart';
import 'package:expense_tracker/core/enums/category_type.dart';
import 'package:expense_tracker/core/models/category.dart';
import 'package:expense_tracker/features/categories/services/categories_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  return CategoriesService();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  bindSupabaseRealtimeAuth(ref);
  return ref.watch(categoriesServiceProvider).watchCategories();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesProvider).valueOrNull
          ?.where((c) => c.type == CategoryType.expense)
          .toList() ??
      const [];
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoriesProvider).valueOrNull
          ?.where((c) => c.type == CategoryType.income)
          .toList() ??
      const [];
});
