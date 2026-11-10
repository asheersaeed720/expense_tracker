import 'package:expense_tracker/core/enums/loan_status.dart';
import 'package:flutter/material.dart';

class LoanStatusBadge extends StatelessWidget {
  const LoanStatusBadge({super.key, required this.status});

  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LoanStatus.pending => ('Pending', const Color(0xFFFBBF24)),
      LoanStatus.partial => ('Partial', const Color(0xFF60A5FA)),
      LoanStatus.settled => ('Settled', const Color(0xFF34D399)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
