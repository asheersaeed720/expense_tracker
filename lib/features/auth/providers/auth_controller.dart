import 'package:expense_tracker/core/utils/auth_error_message.dart';
import 'package:expense_tracker/features/auth/providers/auth_state_provider.dart';
import 'package:expense_tracker/features/auth/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthControllerState {
  const AuthControllerState({this.isLoading = false});

  final bool isLoading;

  AuthControllerState copyWith({bool? isLoading}) {
    return AuthControllerState(isLoading: isLoading ?? this.isLoading);
  }
}

class AuthController extends Notifier<AuthControllerState> {
  @override
  AuthControllerState build() => const AuthControllerState();

  AuthService get _auth => ref.read(authProvider);

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.signInWithEmail(email: email, password: password);
      return null;
    } catch (e) {
      return authErrorMessage(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<({String? error, SignUpResult? result})> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _auth.signUpWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      );
      return (error: null, result: result);
    } catch (e) {
      return (error: authErrorMessage(e), result: null);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.sendPasswordResetEmail(email);
      return null;
    } catch (e) {
      return authErrorMessage(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(AuthController.new);
