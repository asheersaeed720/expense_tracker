import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _longDate = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy');

  static String headerDate(DateTime date) => _longDate.format(date);

  static String transactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return _shortDate.format(date);
  }
}
