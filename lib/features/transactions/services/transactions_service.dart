import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Transaction CRUD via Supabase (Phase 3).
class TransactionsService {
  TransactionsService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  SupabaseClient get client => _client;
}
