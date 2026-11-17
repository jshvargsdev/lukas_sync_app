import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/domain/currency.dart';
import 'package:lukas_sync_app/domain/share_text.dart';
import 'package:lukas_sync_app/models/custom_rate.dart';

import '../helpers/fake_rate_source.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_VE'));

  final options = buildCurrencyOptions(
    rates: sampleRates(),
    customRates: const [
      CustomRate(id: '1', name: 'Paralelo', value: '50', icon: '💵'),
    ],
  );
  final usd = options.firstWhere((o) => o.id == kUsdId);

  test('lista las equivalencias, la fecha de las tasas y la firma', () {
    final text = buildShareText(
      amount: 100,
      from: usd,
      options: options,
      ratesDate: DateTime(2026, 11, 17, 9, 30),
    );
    final lines = text.split('\n');
    expect(lines.first, '100,00 Dólar BCV equivalen a:');
    expect(lines, contains('• 3.651,23 Bolívares'));
    expect(lines, contains('• 91,74 Euro BCV'));
    expect(lines, contains('• 91,28 USDT Binance'));
    expect(lines, contains('• 73,02 Paralelo'));
    expect(lines, isNot(contains(startsWith('• 100,00 Dólar BCV'))));
    expect(lines.last, startsWith('Tasas del 17 nov'));
    expect(lines.last, endsWith('· Lukas Sync'));
  });

  test('omite monedas sin tasa y no falla si no hay ninguna', () {
    final noRates = buildCurrencyOptions(rates: null, customRates: const []);
    final ves = noRates.firstWhere((o) => o.id == kVesId);
    final text = buildShareText(
      amount: 10,
      from: ves,
      options: noRates,
      ratesDate: null,
    );
    expect(text, '10,00 Bolívares\n\nLukas Sync');
  });
}
