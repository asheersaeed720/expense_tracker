import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/core/enums/category_type.dart';
import 'package:expense_tracker/core/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriesService {
  CategoriesService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Stream<List<Category>> watchCategories() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);

    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
      final mapped = rows.map(Category.fromJson).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return mapped;
    });
  }

  Future<List<Category>> fetchByType(CategoryType type) async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client
        .from('categories')
        .select()
        .eq('type', type.value)
        .eq('user_id', userId);

    return rows.map(Category.fromJson).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
    String? color,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('categories').insert({
      'user_id': userId,
      'name': name.trim(),
      'type': type.value,
      'icon': icon,
      'color': color ?? '#A0A0A0',
    });
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String icon,
  }) async {
    await _client.from('categories').update({
      'name': name.trim(),
      'icon': icon,
    }).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    final category = await _client
        .from('categories')
        .select('name, type, user_id')
        .eq('id', id)
        .maybeSingle();

    if (category == null) return;

    final model = Category.fromJson({...category, 'id': id});
    if (model.isProtectedDefault) {
      throw StateError('Default categories cannot be deleted.');
    }

    final inUse = await _client
        .from('transactions')
        .select('id')
        .eq('category_id', id)
        .limit(1);

    if (inUse.isNotEmpty) {
      throw StateError('Category is used by transactions and cannot be deleted.');
    }

    await _client.from('categories').delete().eq('id', id);
  }
}
