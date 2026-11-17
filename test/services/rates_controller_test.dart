import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukas_sync_app/services/rate_source.dart';
import 'package:lukas_sync_app/services/rates_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_rate_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 17, 10);
  });

  RatesController build(RateSource source) =>
      RatesController(source: source, now: () => now);

  test('al iniciar carga la caché de la v1 y luego refresca', () async {
    SharedPreferences.setMockInitialValues({
      '@lukas_rates_cache': jsonEncode({
        'dolarBcv': '30.00',
        'euroBcv': '31.00',
        'usdtBinance': '32.00',
        'fetchedAt': '2026-11-16T12:00:00.000Z',
      }),
    });
    final source = FakeRateSource(
      error: const RateFetchException('Sin conexión a internet.'),
    );
    final c = build(source);
    await c.start();

    expect(source.calls, 1);
    expect(c.rates!.dolarBcv, 30);
    expect(c.errorMessage, 'Sin conexión a internet.');
    c.dispose();
  });

  test('un refresco exitoso guarda caché, limpia el error y avisa', () async {
    final source = FakeRateSource(
      error: const RateFetchException('Sin conexión a internet.'),
    );
    final fetched = [];
    final c = RatesController(
      source: source,
      now: () => now,
      onRatesFetched: fetched.add,
    );
    await c.refresh();
    expect(c.errorMessage, isNotNull);
    expect(c.hasRates, isFalse);

    source
      ..error = null
      ..next = sampleRates();
    await c.refresh();

    expect(c.errorMessage, isNull);
    expect(c.rates!.dolarBcv, 36.5123);
    expect(fetched, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    final cached = jsonDecode(prefs.getString('@lukas_rates_cache')!);
    expect(cached['dolarBcv'], 36.5123);
    c.dispose();
  });

  test('errores inesperados muestran un mensaje genérico', () async {
    final c = build(_ThrowingSource());
    await c.refresh();
    expect(c.errorMessage, 'No se pudieron actualizar las tasas.');
    expect(c.isLoading, isFalse);
    c.dispose();
  });

  test('isStale solo cuando los datos tienen más de 2 horas', () async {
    final c = build(
      FakeRateSource(next: sampleRates(at: DateTime(2026, 11, 17, 9))),
    );
    await c.refresh();
    expect(c.isStale, isFalse);
    now = DateTime(2026, 11, 17, 11, 1);
    expect(c.isStale, isTrue);
    c.dispose();
  });

  test('al volver a la app refresca solo si pasó el intervalo', () async {
    final source = FakeRateSource(next: sampleRates());
    final c = build(source);
    await c.start();
    expect(source.calls, 1);

    now = now.add(const Duration(minutes: 5));
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(source.calls, 1);

    now = now.add(kRefreshInterval);
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(source.calls, 2);
    c.dispose();
  });
}

class _ThrowingSource implements RateSource {
  @override
  Future<Never> fetchRates() async => throw StateError('boom');
}
