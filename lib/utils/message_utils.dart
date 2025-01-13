import 'package:flutter/material.dart';
import '../widgets/glass_snackbar.dart';
import '../widgets/glass_dialog.dart';
void showMessage(BuildContext context, String message, bool isSuccess) {
  ScaffoldMessenger.of(context).showSnackBar(
    GlassSnackBar(
      message: message,
      isSuccess: isSuccess,
    ),
  );
}

Future<bool?> showGlassConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => GlassDialog(
      title: title,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
} 