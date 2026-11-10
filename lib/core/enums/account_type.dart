enum AccountType {
  cash('cash'),
  bank('bank'),
  wallet('wallet');

  const AccountType(this.value);

  final String value;

  static AccountType? fromValue(String? raw) {
    if (raw == null) return null;
    for (final type in AccountType.values) {
      if (type.value == raw) return type;
    }
    return null;
  }
}
