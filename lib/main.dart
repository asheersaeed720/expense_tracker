import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint(details.exceptionAsString());
    }
  };

  await dotenv.load(fileName: '.env');
  await initializeSupabase();

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}
