import 'package:expense_tracker/core/widgets/app_loading_indicator.dart';
import 'package:expense_tracker/features/auth/widgets/expense_tracker_logo.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExpenseTrackerLogo(showTitle: true),
            SizedBox(height: 32),
            AppLoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
