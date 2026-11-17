import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copia [text] y avisa con un snackbar: "Monto copiado: 42,29".
Future<void> copyWithFeedback(
  BuildContext context,
  String text, {
  required String label,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.lightImpact();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$label copiado: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
}
