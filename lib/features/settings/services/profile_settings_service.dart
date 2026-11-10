import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettingsService {
  ProfileSettingsService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  User? get currentUser => _client.auth.currentUser;

  Future<void> updateFullName(String fullName) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
    }).eq('id', userId);

    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': fullName.trim()}),
    );
  }

  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
