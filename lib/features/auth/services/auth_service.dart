import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase auth wrapper (expanded in Phase 1).
class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
