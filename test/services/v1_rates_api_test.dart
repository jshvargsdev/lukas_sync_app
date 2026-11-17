import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lukas_sync_app/services/rate_source.dart';
import 'package:lukas_sync_app/services/v1_rates_api.dart';

V1RatesApi apiReturning(
  int status,
  Object? body, {
  void Function(http.Request)? onRequest,
}) {
  return V1RatesApi(
    baseUrl: 'https://api.test',
    client: MockClient((req) async {
      onRequest?.call(req);
      return http.Response.bytes(
        utf8.encode(body is String ? body : jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

const latest = {
  'bcv': {
    'usd': 236.4583,
    'eur': 274.1032,
    'valueDate': '2026-11-18',
    'fetchedAt': '2026-11-17T21:05:00Z',
  },
  'usdt': {
    'value': 312.5,
    'sampleSize': 10,
    'fetchedAt': '2026-11-17T22:00:00Z',
  },
};

Matcher throwsRateError(String message) => throwsA(
  isA<RateFetchException>().having((e) => e.message, 'message', message),
);

void main() {
  group('fetchRates', () {
    test('lee /v1/rates/latest sin token y sin redondear', () async {
      late http.Request sent;
      final r = await apiReturning(
        200,
        latest,
        onRequest: (req) => sent = req,
      ).fetchRates();

      expect(sent.url.toString(), 'https://api.test/v1/rates/latest');
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(r.dolarBcv, 236.4583);
      expect(r.euroBcv, 274.1032);
      expect(r.usdtBinance, 312.5);
      // Usa el dato más reciente (USDT, 22:00 UTC).
      expect(r.fetchedAt.toUtc(), DateTime.utc(2026, 11, 17, 22));
    });

    test('si Binance falló, el USDT queda en 0 y el BCV se conserva', () async {
      final r = await apiReturning(200, {...latest, 'usdt': null}).fetchRates();
      expect(r.usdtBinance, 0);
      expect(r.dolarBcv, 236.4583);
      expect(r.fetchedAt.toUtc(), DateTime.utc(2026, 11, 17, 21, 5));
    });

    test('acepta una URL base con o sin barra final', () async {
      late Uri url;
      await V1RatesApi(
        baseUrl: 'https://api.test/base/',
        client: MockClient((req) async {
          url = req.url;
          return http.Response(jsonEncode(latest), 200);
        }),
      ).fetchRates();
      expect(url.toString(), 'https://api.test/base/v1/rates/latest');
    });

    test('errores HTTP y datos inválidos dan mensajes en español', () async {
      await expectLater(
        apiReturning(500, {}).fetchRates(),
        throwsRateError('El servicio de tasas no respondió (código 500).'),
      );
      await expectLater(
        apiReturning(200, 'no es json').fetchRates(),
        throwsRateError('El servicio de tasas devolvió datos inválidos.'),
      );
      await expectLater(
        apiReturning(200, {
          'bcv': {'usd': 0, 'eur': 1, 'fetchedAt': '2026-11-17T21:05:00Z'},
        }).fetchRates(),
        throwsRateError('El servicio de tasas devolvió datos inválidos.'),
      );
    });

    test('sin conexión', () async {
      final api = V1RatesApi(
        baseUrl: 'https://api.test',
        client: MockClient((_) async => throw http.ClientException('x')),
      );
      await expectLater(
        api.fetchRates(),
        throwsRateError('Sin conexión a internet.'),
      );
    });
  });

  group('bcvRateOn', () {
    test('pide la fecha en formato AAAA-MM-DD', () async {
      late Uri url;
      final r = await apiReturning(200, {
        'date': '2026-11-15',
        'valueDate': '2026-11-13',
        'usd': 235.91,
        'eur': 273.4,
      }, onRequest: (req) => url = req.url).bcvRateOn(DateTime(2026, 11, 15));

      expect(url.toString(), 'https://api.test/v1/rates/bcv?date=2026-11-15');
      expect(r.usd, 235.91);
      expect(r.valueDate, DateTime(2026, 11, 13));
      expect(r.isFromEarlierDay, isTrue);
    });

    test('404 y 400 tienen mensajes propios', () async {
      await expectLater(
        apiReturning(404, {}).bcvRateOn(DateTime(2020)),
        throwsRateError('No hay tasas guardadas para esa fecha.'),
      );
      await expectLater(
        apiReturning(400, {}).bcvRateOn(DateTime(2030)),
        throwsRateError('La fecha elegida no es válida.'),
      );
    });
  });
}
