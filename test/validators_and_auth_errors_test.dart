import 'package:expense_tracker/core/utils/auth_error_message.dart';
import 'package:expense_tracker/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Validators', () {
    test('email rejects blank and malformed values', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email('  '), 'Email is required');
      expect(Validators.email('not-an-email'), 'Enter a valid email');
      expect(Validators.email('  asheer@example.com  '), isNull);
    });

    test('password enforces length and confirm must match exactly', () {
      expect(Validators.password(''), 'Password is required');
      expect(Validators.password('12345'), 'Password must be at least 6 characters');
      expect(Validators.password('123456'), isNull);
      expect(Validators.confirmPassword('123456', '123456'), isNull);
      expect(
        Validators.confirmPassword('1234567', '123456'),
        'Passwords do not match',
      );
    });
  });

  group('authErrorMessage', () {
    test('maps known auth failures and hides unknown errors', () {
      expect(
        authErrorMessage(const AuthException('Invalid login credentials')),
        'Wrong email or password.',
      );
      expect(
        authErrorMessage(const AuthException('User already registered')),
        'This email is already registered.',
      );
      expect(
        authErrorMessage(Exception('socket down')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
