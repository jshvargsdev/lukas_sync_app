import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón con borde punteado para crear una tasa personalizada.
class AddRateTile extends StatelessWidget {
  final VoidCallback onPress;

  const AddRateTile({super.key, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: p.border),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 20, color: p.textSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Agregar tasa personalizada',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      const Radius.circular(AppRadius.lg),
    );
    final path = Path()..addRRect(rrect);

    const double dashWidth = 6;
    const double dashSpace = 5;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
