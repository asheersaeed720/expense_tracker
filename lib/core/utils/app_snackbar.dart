import 'package:flutter/material.dart';

/// End padding keeps the message clear of the 56px button that paints over the bar.
const EdgeInsetsDirectional _snackBarPadding = EdgeInsetsDirectional.only(
  start: 16,
  top: 14,
  end: 72,
  bottom: 14,
);

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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: _snackBarPadding,
    ),
  );
}
