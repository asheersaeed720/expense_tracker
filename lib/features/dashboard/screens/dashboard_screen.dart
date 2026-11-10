import 'package:flutter/material.dart';

/// Placeholder home — built out in Phase 2.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(
        child: Text('Dashboard — coming in Phase 2'),
      ),
    );
  }
}
