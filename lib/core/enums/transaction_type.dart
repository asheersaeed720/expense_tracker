enum TransactionType {
  expense('expense'),
  income('income');

  const TransactionType(this.value);

  final String value;

  static TransactionType? fromValue(String? raw) {
    if (raw == null) return null;
    for (final type in TransactionType.values) {
      if (type.value == raw) return type;
    }
    return null;
  }
}
