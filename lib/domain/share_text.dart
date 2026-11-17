import 'converter.dart';
import 'currency.dart';
import 'time_format.dart';

/// Texto para compartir una conversión:
///
/// ```
/// 100,00 Dólar BCV equivalen a:
/// • 23.645,83 Bolívares
/// • 86,27 Euro BCV
///
/// Tasas del 17 nov, 9:30 a. m. · Lukas Sync
/// ```
///
/// Omite las monedas sin tasa válida para no compartir montos en 0.
String buildShareText({
  required double amount,
  required CurrencyOption from,
  required List<CurrencyOption> options,
  required DateTime? ratesDate,
}) {
  final lines = <String>[];
  for (final o in options) {
    if (o.id == from.id || o.rateInVes <= 0) continue;
    final converted = convertAmount(
      amount: amount,
      fromRateInVes: from.rateInVes,
      toRateInVes: o.rateInVes,
    );
    lines.add('• ${formatVes(converted)} ${o.name}');
  }

  final header = '${formatVes(amount)} ${from.name}';
  final buffer = StringBuffer()
    ..writeln(lines.isEmpty ? header : '$header equivalen a:');
  for (final l in lines) {
    buffer.writeln(l);
  }
  buffer.writeln();
  buffer.write(
    ratesDate != null
        ? 'Tasas del ${formatDateTime(ratesDate)} · Lukas Sync'
        : 'Lukas Sync',
  );
  return buffer.toString();
}
