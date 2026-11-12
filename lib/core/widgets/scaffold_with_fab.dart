import 'package:flutter/material.dart';

/// The button is a sibling of the [Scaffold], painted after it.
/// A floating [SnackBar] on that scaffold stays at the bottom, under the button.
class ScaffoldWithFab extends StatelessWidget {
  const ScaffoldWithFab({
    super.key,
    this.appBar,
    required this.body,
    required this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final bottom = kFloatingActionButtonMargin + MediaQuery.viewPaddingOf(context).bottom;

    return Stack(
      children: [
        Scaffold(appBar: appBar, body: body),
        PositionedDirectional(
          end: kFloatingActionButtonMargin,
          bottom: bottom,
          child: floatingActionButton,
        ),
      ],
    );
  }
}
