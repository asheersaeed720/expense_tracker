import 'package:expense_tracker/features/auth/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-subscribes Supabase `.stream()` listeners when the JWT changes (refresh, sign-in, sign-out).
void bindSupabaseRealtimeAuth(Ref ref) {
  ref.watch(
    currentSessionProvider.select((session) => session?.accessToken),
  );
}
