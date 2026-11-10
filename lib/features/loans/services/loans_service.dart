import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loans CRUD via Supabase (Phase 4).
class LoansService {
  LoansService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  SupabaseClient get client => _client;
}
