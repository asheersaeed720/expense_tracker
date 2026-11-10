import 'package:expense_tracker/config/constants/app_constants.dart';
import 'package:expense_tracker/core/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppLoadingIndicator(
        message: AppConstants.appName,
      ),
    );
  }
}
