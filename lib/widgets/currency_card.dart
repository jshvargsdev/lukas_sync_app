import 'package:flutter/material.dart';

class CurrencyCard extends StatelessWidget {
  final String title;
  final String amount;
  final String variation;
  final bool isActive;
  final String icon;
  final VoidCallback onPress;
  final VoidCallback? onLongPress;
  final double width;

  const CurrencyCard({
    super.key,
    required this.title,
    required this.amount,
    required this.variation,
    required this.icon,
    required this.onPress,
    required this.width,
    this.isActive = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isActive
        ? (isDark ? const Color(0x4D14532D) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final Color borderColor = isActive
        ? (isDark ? const Color(0xFF15803D) : const Color(0xFFBBF7D0))
        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9));
    final Color iconBg =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final Color titleColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final Color amountColor = isDark ? Colors.white : Colors.black;
    final Color variationColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final amountStyle = TextStyle(
      color: amountColor,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    );

    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPress,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previous,
                        ?current,
                      ],
                    ),
                    child: FittedBox(
                      key: ValueKey<String>(amount),
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(amount, maxLines: 1, style: amountStyle),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    variation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: variationColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
