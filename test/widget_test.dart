import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/config/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Kharcha app loads login placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          goRouterProvider.overrideWith(
            (ref) => GoRouter(
              initialLocation: '/login',
              routes: [
                GoRoute(
                  path: '/login',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Login')),
                  ),
                ),
              ],
            ),
          ),
        ],
        child: const KharchaApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
