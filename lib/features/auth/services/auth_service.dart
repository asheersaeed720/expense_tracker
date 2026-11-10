import 'package:expense_tracker/config/constants/app_constants.dart';
import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await _ensureUserBootstrap(user);
    }
  }

  Future<SignUpResult> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign up failed');
    }

    if (response.session != null) {
      await _createProfileAndDefaults(
        userId: user.id,
        fullName: fullName.trim(),
      );
      return SignUpResult.signedIn;
    }

    return SignUpResult.confirmationEmailSent;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> _ensureUserBootstrap(User user) async {
    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      final metaName = user.userMetadata?['full_name'];
      final name = metaName is String && metaName.trim().isNotEmpty
          ? metaName.trim()
          : 'User';
      await _createProfileAndDefaults(userId: user.id, fullName: name);
      return;
    }

    final accounts = await _client
        .from('accounts')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if (accounts.isEmpty) {
      await _seedDefaultAccounts(user.id);
    }
  }

  Future<void> _createProfileAndDefaults({
    required String userId,
    required String fullName,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'full_name': fullName,
      'currency': AppConstants.defaultCurrency,
    });

    await _seedDefaultAccounts(userId);
  }

  Future<void> _seedDefaultAccounts(String userId) async {
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
  }
}

enum SignUpResult {
  signedIn,
  confirmationEmailSent,
}
