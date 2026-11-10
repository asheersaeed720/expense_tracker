import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _amountFormat = NumberFormat('#,##0.##');

  static String format(double amount, {String currencyCode = 'PKR'}) {
    return '$currencyCode ${_amountFormat.format(amount)}';
  }
}
