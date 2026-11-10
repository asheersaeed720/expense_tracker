enum LoanStatus {
  pending('pending'),
  partial('partial'),
  settled('settled');

  const LoanStatus(this.value);

  final String value;
}
