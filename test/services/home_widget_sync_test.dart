import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/models/rates.dart';
import 'package:lukas_sync_app/services/home_widget_sync.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_VE'));

  test('el widget recibe las tasas formateadas y la hora', () {
    final data = widgetDataFor(
      Rates(
        dolarBcv: 236.4583,
        euroBcv: 274.1032,
        usdtBinance: 1312.5,
        fetchedAt: DateTime(2026, 11, 17, 9, 30),
      ),
    );
    expect(data[WidgetKeys.usd], '236,46');
    expect(data[WidgetKeys.eur], '274,10');
    expect(data[WidgetKeys.usdt], '1.312,50');
    expect(data[WidgetKeys.updated], startsWith('17 nov'));
  });

  test('sin tasa (0) el widget muestra un guion', () {
    final data = widgetDataFor(
      Rates(
        dolarBcv: 915.7476,
        euroBcv: 1008.3113674,
        usdtBinance: 0,
        fetchedAt: DateTime(2026, 11, 17, 9, 30),
      ),
    );
    expect(data[WidgetKeys.usd], '915,75');
    expect(data[WidgetKeys.eur], '1.008,31');
    expect(data[WidgetKeys.usdt], '—');
  });
}
