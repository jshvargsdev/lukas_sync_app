import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class CustomKeypad extends StatelessWidget {
  final void Function(String key) onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onReset;

  /// Alto de cada tecla; el Home lo reduce en pantallas bajas.
  final double keyHeight;

  const CustomKeypad({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onReset,
    this.keyHeight = 54,
  });

  static const List<List<String>> _layout = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['reset', '0', 'backspace'],
  ];

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border(top: BorderSide(color: p.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _layout)
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Row(
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(child: _buildKey(context, row[i])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKey(BuildContext context, String key) {
    final p = context.palette;
    late final Widget content;
    late final VoidCallback action;
    String? semantics;
    var bg = p.surfaceMuted;

    switch (key) {
      case 'backspace':
        semantics = 'Borrar';
        content = Icon(
          Icons.backspace_outlined,
          size: 22,
          color: p.textSecondary,
        );
        action = () {
          HapticFeedback.selectionClick();
          onBackspace();
        };
      case 'reset':
        semantics = 'Limpiar';
        bg = p.dangerSoft;
        content = Text(
          'C',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: p.danger,
          ),
        );
        action = () {
          HapticFeedback.mediumImpact();
          onReset();
        };
      default:
        content = Text(
          key,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: p.textPrimary,
          ),
        );
        action = () {
          HapticFeedback.selectionClick();
          onKeyPress(key);
        };
    }

    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: action,
          onLongPress: key == 'backspace' ? onReset : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: keyHeight,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
