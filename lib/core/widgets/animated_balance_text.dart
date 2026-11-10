import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class AnimatedBalanceText extends StatelessWidget {
  const AnimatedBalanceText({
    super.key,
    required this.amount,
    this.currency = 'PKR',
    this.style,
  });

  final double amount;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          CurrencyFormatter.format(value, currencyCode: currency),
          style: style,
        );
      },
    );
  }
}
