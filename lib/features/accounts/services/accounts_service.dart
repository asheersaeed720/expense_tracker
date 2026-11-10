import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Accounts CRUD via Supabase (Phase 2).
class AccountsService {
  AccountsService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  SupabaseClient get client => _client;
}
