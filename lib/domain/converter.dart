import 'dart:math' as math;

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

/// Formatea una tasa (Bs por unidad). Desde 1 Bs usa 2 decimales; por
/// debajo usa los necesarios para mostrar 2 cifras significativas, para que
/// tasas como la del peso colombiano (0,061) no se vean como 0,06 o 0,00.
String formatRate(double rate) {
  if (!rate.isFinite || rate <= 0) return formatVes(0);
  if (rate >= 1) return formatVes(rate);
  final leadingZeros = (-math.log(rate) / math.ln10).floor();
  final maxDecimals = (leadingZeros + 2).clamp(2, kMaxRateDecimals);
  final f = NumberFormat.decimalPattern('es_VE')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = maxDecimals;
  return f.format(rate);
}

/// Máximo de decimales que se aceptan al escribir una tasa.
const int kMaxRateDecimals = 6;

/// Interpreta una tasa escrita por el usuario. Acepta coma o punto como
/// separador decimal (no hay separador de miles). Devuelve null si el texto
/// no es un número válido.
double? parseRateInput(String input) {
  final t = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d*)?$|^\.\d+$').hasMatch(t)) return null;
  return double.tryParse(t);
}

/// Tasa guardada → texto editable: 290 → "290", 36.5 → "36,5", 0.061 → "0,061".
String formatRateForInput(double rate) =>
    NumberFormat('0.######', 'es_VE').format(rate);
