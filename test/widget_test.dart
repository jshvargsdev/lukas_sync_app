import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/main.dart';
import 'package:lukas_sync_app/services/rate_source.dart';
import 'package:lukas_sync_app/services/rates_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_rate_source.dart';

Future<void> pumpApp(WidgetTester tester, RateSource source) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  ratesController = RatesController(source: source, settings: appSettings);
  await tester.pumpWidget(const LukasSyncApp());
  await tester.runAsync(ratesController.refresh);
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es_VE');
  });

  testWidgets('arranca y muestra el título y las monedas', (tester) async {
    await pumpApp(tester, FakeRateSource(next: sampleRates()));
    expect(find.text('Lukas Sync'), findsOneWidget);
    expect(find.text('Dólar BCV'), findsOneWidget);
    expect(find.text('USDT Binance'), findsOneWidget);
  });

  testWidgets('al elegir dólar y teclear 1,00 muestra los bolívares', (
    tester,
  ) async {
    await pumpApp(tester, FakeRateSource(next: sampleRates()));

    await tester.tap(find.text('Dólar BCV'));
    await tester.pump();
    for (final k in ['1', '0', '0']) {
      await tester.tap(find.widgetWithText(InkWell, k).last);
      await tester.pump();
    }

    // Hero con el monto tecleado y caption con la tasa completa redondeada.
    expect(find.text('1 Dólar BCV = 36,51 Bs'), findsOneWidget);
    expect(find.text('1,00'), findsOneWidget);
    // Bolívares: 1 × 36,5123.
    expect(find.text('36,51'), findsOneWidget);
  });

  testWidgets('sin tasas y con error muestra el aviso para reintentar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      FakeRateSource(
        error: const RateFetchException('Sin conexión a internet.'),
      ),
    );
    expect(find.text('Sin conexión a internet.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('mantener una moneda permite copiar su monto', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await pumpApp(tester, FakeRateSource(next: sampleRates()));

    await tester.tap(find.text('Dólar BCV'));
    await tester.pump();
    for (final k in ['5', '0', '0']) {
      await tester.tap(find.widgetWithText(InkWell, k).last);
      await tester.pump();
    }
    await tester.longPress(find.text('Bolívares'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar 182,56'));
    await tester.pumpAndSettle();

    expect(copied, '182,56');
    expect(find.text('Monto copiado: 182,56'), findsOneWidget);
  });
}
