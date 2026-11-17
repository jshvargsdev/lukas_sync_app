import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/domain/converter.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_VE'));

  group('convertAmount', () {
    test('de dólares a bolívares multiplica por la tasa', () {
      expect(
        convertAmount(amount: 100, fromRateInVes: 36.5, toRateInVes: 1),
        3650,
      );
    });

    test('de bolívares a dólares divide por la tasa', () {
      expect(
        convertAmount(amount: 3650, fromRateInVes: 1, toRateInVes: 36.5),
        100,
      );
    });

    test('entre dos monedas extranjeras pasa por bolívares', () {
      // 100 USD a 40 Bs = 4000 Bs; 4000 / 50 = 80 EUR.
      expect(
        convertAmount(amount: 100, fromRateInVes: 40, toRateInVes: 50),
        80,
      );
    });

    test('usa la tasa completa, sin redondear a 2 decimales', () {
      final r = convertAmount(
        amount: 1000000,
        fromRateInVes: 36.5123,
        toRateInVes: 1,
      );
      expect(r, closeTo(36512300, 0.001));
    });

    test('devuelve 0 si alguna tasa es 0, negativa o no finita', () {
      expect(convertAmount(amount: 10, fromRateInVes: 0, toRateInVes: 1), 0);
      expect(convertAmount(amount: 10, fromRateInVes: 1, toRateInVes: 0), 0);
      expect(convertAmount(amount: 10, fromRateInVes: -2, toRateInVes: 1), 0);
      expect(
        convertAmount(
          amount: 10,
          fromRateInVes: double.nan,
          toRateInVes: 1,
        ),
        0,
      );
    });
  });

  group('centsInputToAmount', () {
    test('interpreta la entrada como centavos', () {
      expect(centsInputToAmount('12345'), 123.45);
      expect(centsInputToAmount('0'), 0);
      expect(centsInputToAmount('999999999999'), 9999999999.99);
    });

    test('entrada inválida vale 0', () {
      expect(centsInputToAmount(''), 0);
    });
  });

  test('formatVes usa formato venezolano', () {
    expect(formatVes(1234567.891), '1.234.567,89');
    expect(formatVes(0), '0,00');
  });
}
