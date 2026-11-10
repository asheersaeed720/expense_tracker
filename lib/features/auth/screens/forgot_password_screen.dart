import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/validators.dart';
import 'package:expense_tracker/features/auth/providers/auth_controller.dart';
import 'package:expense_tracker/features/auth/widgets/auth_primary_button.dart';
import 'package:expense_tracker/features/auth/widgets/auth_screen_layout.dart';
import 'package:expense_tracker/features/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text);

    if (!mounted) return;

    if (error != null) {
      showAppSnackBar(context, message: error, isError: true);
      return;
    }

    showAppSnackBar(
      context,
      message: 'If an account exists for this email, we sent a reset link.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScreenLayout(
      title: 'Reset password',
      subtitle:
          'Enter your email and we will send you a link to reset your password.',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: isLoading ? null : () => context.pop(),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Send reset link',
              isLoading: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
