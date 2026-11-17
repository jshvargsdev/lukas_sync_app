import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'currency_tile.dart';

/// Tarjeta superior con la moneda activa y el monto que se está escribiendo.
class AmountHero extends StatelessWidget {
  final String icon;
  final String name;
  final String amount;
  final String caption;
  final List<Widget> actions;
  final VoidCallback? onAmountTap;

  const AmountHero({
    super.key,
    required this.icon,
    required this.name,
    required this.amount,
    required this.caption,
    this.actions = const [],
    this.onAmountTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CurrencyAvatar(icon: icon, size: 30, background: p.accentSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onAmountTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    maxLines: 1,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      fontFeatures: kTabularFigures,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 13,
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
