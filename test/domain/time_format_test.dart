import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/domain/time_format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_VE'));

  final now = DateTime(2026, 11, 17, 12);

  test('menos de un minuto o en el futuro', () {
    expect(
      formatAge(now.subtract(const Duration(seconds: 30)), now: now),
      'hace un momento',
    );
    expect(
      formatAge(now.add(const Duration(minutes: 3)), now: now),
      'hace un momento',
    );
  });

  test('minutos y horas', () {
    expect(
      formatAge(now.subtract(const Duration(minutes: 5)), now: now),
      'hace 5 min',
    );
    expect(
      formatAge(now.subtract(const Duration(minutes: 125)), now: now),
      'hace 2 h',
    );
  });

  test('un día o más muestra la fecha', () {
    final r = formatAge(DateTime(2026, 11, 15, 9, 30), now: now);
    expect(r, startsWith('15 nov'));
  });
}
