import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return 'Wrong email or password.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'This email is already registered.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (message.contains('password')) {
      return error.message;
    }

    return error.message;
  }

  return 'Something went wrong. Please try again.';
}
