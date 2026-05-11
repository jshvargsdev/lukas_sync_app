import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/custom_rate.dart';

class ReorderRatesScreen extends StatefulWidget {
  const ReorderRatesScreen({super.key});

  @override
  State<ReorderRatesScreen> createState() => _ReorderRatesScreenState();
}

class _ReorderRatesScreenState extends State<ReorderRatesScreen> {
  late List<CustomRate> _rates;

  static final NumberFormat _veFormat = NumberFormat.decimalPatternDigits(
    locale: 'es_VE',
    decimalDigits: 2,
  );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Reordenar tasas',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: _rates.isEmpty
          ? Center(
              child: Text(
                'No hay tasas personalizadas',
                style: TextStyle(color: subTextColor),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _rates.length,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _rates.removeAt(oldIndex);
                  _rates.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final r = _rates[index];
                final rateNum = double.tryParse(r.value) ?? 0;
                return Container(
                  key: ValueKey(r.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                      ),
                      child: Text(r.icon,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Tasa: ${_veFormat.format(rateNum)}',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle, color: subTextColor),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
