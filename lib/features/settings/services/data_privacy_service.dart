import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/features/categories/services/categories_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataPrivacyService {
  DataPrivacyService({
    SupabaseClient? client,
    CategoriesService? categoriesService,
  })  : _client = client ?? supabase,
        _categoriesService = categoriesService ?? CategoriesService();

  final SupabaseClient _client;
  final CategoriesService _categoriesService;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> deleteAllUserData() async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('company_transactions').delete().eq('user_id', userId);
    await _client.from('company_ledgers').delete().eq('user_id', userId);
    await _client.from('profiles').update({
      'company_mode_enabled': false,
    }).eq('id', userId);

    await _client.from('loan_payments').delete().eq('user_id', userId);
    await _client.from('loans').delete().eq('user_id', userId);
    await _client.from('transactions').delete().eq('user_id', userId);
    await _client.from('categories').delete().eq('user_id', userId);
    await _client.from('accounts').delete().eq('user_id', userId);

    await _client.from('accounts').insert([
      {
        'user_id': userId,
        'name': 'Cash in Hand',
        'type': 'cash',
        'is_default': true,
        'balance': 0,
      },
      {
        'user_id': userId,
        'name': 'Bank Account',
        'type': 'bank',
        'is_default': false,
        'balance': 0,
      },
    ]);

    await _categoriesService.seedDefaultCategories(userId);
  }
}
