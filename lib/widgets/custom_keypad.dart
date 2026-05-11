import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomKeypad extends StatelessWidget {
  final void Function(String key) onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onReset;

  const CustomKeypad({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onReset,
  });

  static const List<List<String>> _layout = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['reset', '0', 'backspace'],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color digitColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _layout.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) {
                Widget content;
                VoidCallback action;
                if (key == 'backspace') {
                  content = const Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: Color(0xFF64748B),
                  );
                  action = () {
                    HapticFeedback.selectionClick();
                    onBackspace();
                  };
                } else if (key == 'reset') {
                  content = const Text(
                    'C',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF43F5E),
                    ),
                  );
                  action = () {
                    HapticFeedback.mediumImpact();
                    onReset();
                  };
                } else {
                  content = Text(
                    key,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: digitColor,
                    ),
                  );
                  action = () {
                    HapticFeedback.selectionClick();
                    onKeyPress(key);
                  };
                }
                return Expanded(
                  child: InkWell(
                    onTap: action,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 40,
                      child: Center(child: content),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
