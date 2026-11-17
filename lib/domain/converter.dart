import 'package:intl/intl.dart';

/// Convierte [amount] de una moneda a otra usando sus tasas en bolívares.
///
/// Devuelve 0 si alguna tasa no es válida (0, negativa o no finita), para no
/// mostrar montos engañosos mientras las tasas aún no cargan.
double convertAmount({
  required double amount,
  required double fromRateInVes,
  required double toRateInVes,
}) {
  if (!_isValidRate(fromRateInVes) || !_isValidRate(toRateInVes)) return 0;
  return amount * fromRateInVes / toRateInVes;
}

bool _isValidRate(double r) => r.isFinite && r > 0;

/// Interpreta la entrada del teclado, que se escribe en centavos.
/// "12345" → 123.45
double centsInputToAmount(String input) => (int.tryParse(input) ?? 0) / 100.0;

final NumberFormat _veFormat = NumberFormat.decimalPatternDigits(
  locale: 'es_VE',
  decimalDigits: 2,
);

/// Formato venezolano con 2 decimales: 1.234,50
String formatVes(double value) => _veFormat.format(value);
