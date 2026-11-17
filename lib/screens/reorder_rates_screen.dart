import 'package:flutter/material.dart';

import '../domain/converter.dart';
import '../main.dart';
import '../models/custom_rate.dart';
import '../models/rates.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_tile.dart';

class ReorderRatesScreen extends StatefulWidget {
  const ReorderRatesScreen({super.key});

  @override
  State<ReorderRatesScreen> createState() => _ReorderRatesScreenState();
}

class _ReorderRatesScreenState extends State<ReorderRatesScreen> {
  late List<CustomRate> _rates;

  @override
  void initState() {
    super.initState();
    _rates = List.of(customRatesStore.rates);
  }

  Future<void> _save() async {
    await customRatesStore.reorder(_rates);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reordenar tasas'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Guardar')),
          const SizedBox(width: 8),
        ],
      ),
      body: _rates.isEmpty
          ? Center(
              child: Text(
                'No hay tasas personalizadas',
                style: TextStyle(color: p.textSecondary),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _rates.length,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 6,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: child,
              ),
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _rates.removeAt(oldIndex);
                  _rates.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final r = _rates[index];
                return Container(
                  key: ValueKey(r.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: p.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: CurrencyAvatar(icon: r.icon),
                    title: Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Tasa ${formatVes(Rates.parseRate(r.value))}',
                      style: TextStyle(color: p.textSecondary, fontSize: 13),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: p.textTertiary,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
