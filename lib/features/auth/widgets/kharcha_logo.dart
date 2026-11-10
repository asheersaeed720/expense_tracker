import 'package:expense_tracker/config/constants/app_constants.dart';
import 'package:flutter/material.dart';

class KharchaLogo extends StatelessWidget {
  const KharchaLogo({super.key, this.size = 88, this.showTitle = true});

  final double size;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: primary.withValues(alpha: 0.35)),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            size: size * 0.48,
            color: primary,
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 16),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ],
    );
  }
}
