import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/main.dart';
import 'package:lukas_sync_app/models/rates.dart';
import 'package:lukas_sync_app/services/rate_source.dart';
import 'package:lukas_sync_app/services/rates_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_rate_source.dart';

Future<void> pumpApp(WidgetTester tester, RateSource source) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  ratesController = RatesController(source: source);
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

  testWidgets('cada equivalencia tiene su botón para copiar el monto', (
    tester,
  ) async {
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

    // 10.000,00 Bs (se teclea en centavos).
    for (final k in ['1', '0', '0', '0', '0', '0', '0']) {
      await tester.tap(find.widgetWithText(InkWell, k).last);
      await tester.pump();
    }
    expect(find.text('10.000,00'), findsOneWidget);
    // Arriba ya no hay botón de copiar.
    expect(find.byTooltip('Copiar monto'), findsNothing);

    await tester.tap(find.byTooltip('Copiar monto en Dólar BCV'));
    await tester.pumpAndSettle();

    // 10.000 / 36,5123 = 273,88
    expect(copied, '273,88');
    expect(find.text('Monto copiado: 273,88'), findsOneWidget);
  });

  testWidgets('el botón de apariencia del Home cambia el tema', (tester) async {
    await pumpApp(tester, FakeRateSource(next: sampleRates()));
    addTearDown(() => appSettings.setThemeMode(ThemeMode.system));
    expect(find.byIcon(Icons.settings_outlined), findsNothing);

    await tester.tap(find.byTooltip('Apariencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(appSettings.themeMode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('@lukas_theme_mode'), ThemeMode.dark.index);
  });

  testWidgets('se puede crear una tasa menor a 1 Bs sin perder decimales', (
    tester,
  ) async {
    await pumpApp(tester, FakeRateSource(next: sampleRates()));
    addTearDown(() async {
      for (final r in customRatesStore.rates) {
        await customRatesStore.delete(r.id);
      }
    });

    await tester.scrollUntilVisible(
      find.text('Agregar tasa personalizada'),
      200,
    );
    await tester.tap(find.text('Agregar tasa personalizada'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Peso colombiano');
    await tester.enterText(find.byType(TextField).at(1), '0,061');
    await tester.pump();
    expect(find.text('1 unidad = 0,061 Bs'), findsOneWidget);

    // Letras o un segundo separador se ignoran.
    await tester.enterText(find.byType(TextField).at(1), '0,06a1');
    await tester.pump();
    expect(find.text('0,061'), findsOneWidget);

    await tester.tap(find.text('Agregar tasa'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(customRatesStore.rates.single.value, '0.061');
    // Al crearla queda activa: el caption muestra la tasa completa.
    expect(find.text('1 Peso colombiano = 0,061 Bs'), findsOneWidget);
  });

  testWidgets('sin USDT muestra "Tasa no disponible" y no permite copiar', (
    tester,
  ) async {
    final r = sampleRates();
    await pumpApp(
      tester,
      FakeRateSource(
        next: Rates(
          dolarBcv: r.dolarBcv,
          euroBcv: r.euroBcv,
          usdtBinance: 0,
          fetchedAt: r.fetchedAt,
        ),
      ),
    );
    expect(find.text('Tasa no disponible'), findsOneWidget);
    expect(find.byTooltip('Copiar monto en USDT Binance'), findsNothing);
    expect(find.byTooltip('Copiar monto en Dólar BCV'), findsOneWidget);
  });
}
