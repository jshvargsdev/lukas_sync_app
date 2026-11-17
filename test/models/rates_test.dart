import 'package:flutter_test/flutter_test.dart';
import 'package:lukas_sync_app/models/rates.dart';

void main() {
  test('lee la caché de la v1 (tasas como strings)', () {
    final r = Rates.fromCacheJson({
      'dolarBcv': '36.50',
      'euroBcv': '39.80',
      'usdtBinance': '37.10',
      'fetchedAt': '2026-05-11T12:00:00.000Z',
    })!;
    expect(r.dolarBcv, 36.5);
    expect(r.euroBcv, 39.8);
    expect(r.usdtBinance, 37.1);
    expect(r.fetchedAt.toUtc(), DateTime.utc(2026, 5, 11, 12));
  });

  test('ida y vuelta por la caché conserva todos los decimales', () {
    final original = Rates(
      dolarBcv: 36.51234567,
      euroBcv: 39.8,
      usdtBinance: 40.01,
      fetchedAt: DateTime.utc(2026, 11, 17, 13),
    );
    final r = Rates.fromCacheJson(original.toCacheJson())!;
    expect(r.dolarBcv, 36.51234567);
    expect(r.fetchedAt.toUtc(), original.fetchedAt);
  });

  test('caché sin fecha válida se descarta', () {
    expect(Rates.fromCacheJson({'dolarBcv': 1}), isNull);
  });

  test('fromApiData acepta números y strings', () {
    final r = Rates.fromApiData({
      'fetchedAt': '2026-05-11T12:00:00Z',
      'bcv': {
        'dollar': {'value': 36.5123},
        'euro': {'value': '39.8'},
      },
      'binance': {'value': 37},
    });
    expect(r.dolarBcv, 36.5123);
    expect(r.euroBcv, 39.8);
    expect(r.usdtBinance, 37);
  });
}
