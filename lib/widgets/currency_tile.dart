import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Círculo con el emoji/bandera de una moneda.
class CurrencyAvatar extends StatelessWidget {
  final String icon;
  final double size;
  final Color? background;

  const CurrencyAvatar({
    super.key,
    required this.icon,
    this.size = 40,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? context.palette.surfaceMuted,
        shape: BoxShape.circle,
      ),
      child: Text(icon, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Fila de una moneda convertida dentro de la lista del Home.
class CurrencyTile extends StatelessWidget {
  final String icon;
  final String name;
  final String subtitle;
  final String amount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CurrencyTile({
    super.key,
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CurrencyAvatar(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 13,
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amount,
                  maxLines: 1,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
