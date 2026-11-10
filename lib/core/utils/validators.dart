class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final raw = value ?? '';
    if (raw.isEmpty) return 'Password is required';
    if (raw.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    final err = Validators.password(value);
    if (err != null) return err;
    if (value != originalPassword) return 'Passwords do not match';
    return null;
  }

  static String? requiredText(String? value, {String fieldName = 'This field'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$fieldName is required';
    return null;
  }
}
