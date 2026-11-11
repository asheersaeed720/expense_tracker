import 'package:flutter/material.dart';

EdgeInsets _floatingSnackBarMargin(BuildContext context) {
  const horizontal = 16.0;
  const gapAboveFab = 12.0;

  var bottom = 16.0 + MediaQuery.paddingOf(context).bottom;

  final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
  if (scaffold?.floatingActionButton != null) {
    bottom += kFloatingActionButtonMargin +
        kMinInteractiveDimension +
        gapAboveFab;
  }

  return EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottom);
}

void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      margin: _floatingSnackBarMargin(context),
    ),
  );
}
