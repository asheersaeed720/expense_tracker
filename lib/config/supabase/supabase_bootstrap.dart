import 'package:expense_tracker/config/constants/env_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  if (!EnvConstants.isConfigured) {
    throw StateError(
      'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env',
    );
  }

  await Supabase.initialize(
    url: EnvConstants.supabaseUrl,
    publishableKey: EnvConstants.supabaseAnonKey,
    debug: kDebugMode,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
