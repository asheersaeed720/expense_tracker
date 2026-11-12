import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/widgets/scaffold_with_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('snackbar stays at the bottom behind the floating button', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ScaffoldWithFab(
          floatingActionButton: FloatingActionButton(
            onPressed: () => tapped = true,
            child: const Icon(Icons.add),
          ),
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showAppSnackBar(context, message: 'Saved'),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    final bar = tester.getRect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)),
    );
    final fab = tester.getRect(find.byType(FloatingActionButton));

    expect(bar.top, lessThan(fab.bottom));
    expect(bar.bottom, greaterThan(fab.top));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
