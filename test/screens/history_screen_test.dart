import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/models/bcv_historic_rate.dart';
import 'package:lukas_sync_app/screens/history_screen.dart';
import 'package:lukas_sync_app/services/rate_source.dart';
import 'package:lukas_sync_app/services/v1_rates_api.dart';
import 'package:lukas_sync_app/theme/app_theme.dart';

class FakeHistory implements RateHistorySource {
  final List<DateTime> asked = [];
  BcvHistoricRate Function(DateTime date)? answer;
  RateFetchException? error;

  @override
  Future<BcvHistoricRate> bcvRateOn(DateTime date) async {
    asked.add(date);
    final e = error;
    if (e != null) throw e;
    return answer!(date);
  }
}

BcvHistoricRate rateFor(DateTime date, {DateTime? valueDate}) =>
    BcvHistoricRate(
      date: date,
      valueDate: valueDate ?? date,
      usd: 235.9123,
      eur: 273.4,
    );

Future<void> pumpHistory(WidgetTester tester, RateHistorySource? source) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(Brightness.light),
      locale: const Locale('es', 'VE'),
      supportedLocales: const [Locale('es', 'VE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HistoryScreen(
        source: source,
        // Martes 17 de noviembre de 2026.
        now: () => DateTime(2026, 11, 17, 10),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es_VE'));

  testWidgets('por defecto consulta ayer y muestra dólar y euro', (
    tester,
  ) async {
    final source = FakeHistory()..answer = rateFor;
    await pumpHistory(tester, source);

    expect(source.asked, [DateTime(2026, 11, 16)]);
    expect(find.text('Lunes, 16 de noviembre de 2026'), findsOneWidget);
    expect(find.text('235,91 Bs'), findsOneWidget);
    expect(find.text('273,40 Bs'), findsOneWidget);
    expect(find.textContaining('no hubo publicación'), findsNothing);
  });

  testWidgets('en fin de semana aclara la fecha valor que aplica', (
    tester,
  ) async {
    final source = FakeHistory()
      ..answer = (d) => rateFor(d, valueDate: DateTime(2026, 11, 13));
    await pumpHistory(tester, source);

    expect(
      find.text(
        'Ese día no hubo publicación del BCV. Aplica la tasa con fecha '
        'valor del viernes 13 de noviembre.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('elegir otra fecha vuelve a consultar', (tester) async {
    final source = FakeHistory()..answer = rateFor;
    await pumpHistory(tester, source);

    await tester.tap(find.text('Lunes, 16 de noviembre de 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(source.asked.last, DateTime(2026, 11, 10));
    expect(find.text('Martes, 10 de noviembre de 2026'), findsOneWidget);
  });

  testWidgets('sin datos para la fecha muestra el mensaje y reintentar', (
    tester,
  ) async {
    final source = FakeHistory()
      ..error = const RateFetchException(
        'No hay tasas guardadas para esa fecha.',
      );
    await pumpHistory(tester, source);

    expect(find.text('No hay tasas guardadas para esa fecha.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('sin la API v1 configurada lo explica sin reintentar', (
    tester,
  ) async {
    await pumpHistory(tester, null);
    expect(find.textContaining('nuevo servicio de tasas'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });
}
