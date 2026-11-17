import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/models/bcv_publication.dart';
import 'package:lukas_sync_app/screens/history_screen.dart';
import 'package:lukas_sync_app/services/rate_source.dart';
import 'package:lukas_sync_app/services/v1_rates_api.dart';
import 'package:lukas_sync_app/theme/app_theme.dart';

/// Publicaciones de lunes a viernes desde el miércoles 18/11/2026 (la
/// "próxima") hacia atrás, con tasas que bajan 0,5 por día hábil.
List<BcvPublication> businessDays(int count) {
  final out = <BcvPublication>[];
  var d = DateTime(2026, 11, 18);
  var usd = 236.5;
  while (out.length < count) {
    if (d.weekday <= 5) {
      out.add(BcvPublication(valueDate: d, usd: usd, eur: usd + 37.6));
      usd -= 0.5;
    }
    d = d.subtract(const Duration(days: 1));
  }
  return out;
}

class FakeHistory implements RateHistorySource {
  final List<BcvPublication> all;
  final List<DateTime?> asked = [];
  RateFetchException? error;

  FakeHistory(this.all);

  @override
  Future<BcvHistoryPage> bcvHistory({DateTime? before, int limit = 30}) async {
    asked.add(before);
    final e = error;
    if (e != null) throw e;
    final items = all
        .where((p) => before == null || p.valueDate.isBefore(before))
        .take(limit)
        .toList();
    final more = items.isNotEmpty && all.last != items.last;
    return BcvHistoryPage(
      items: items,
      nextBefore: more ? items.last.valueDate : null,
    );
  }
}

Future<void> pumpHistory(WidgetTester tester, RateHistorySource source) async {
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

  testWidgets('un card por publicación con dólar y euro y sus badges', (
    tester,
  ) async {
    await pumpHistory(tester, FakeHistory(businessDays(5)));

    expect(find.text('NOVIEMBRE 2026'), findsOneWidget);
    expect(find.byType(PublicationCard), findsNWidgets(5));
    // Miércoles 18 es la próxima; martes 17 (hoy) la vigente.
    expect(find.text('Próxima'), findsOneWidget);
    expect(find.text('Vigente'), findsOneWidget);
    final vigente = find.ancestor(
      of: find.text('Vigente'),
      matching: find.byType(PublicationCard),
    );
    expect(
      find.descendant(of: vigente, matching: find.text('Mar 17 de noviembre')),
      findsOneWidget,
    );
    // Sábado y domingo no aparecen.
    expect(find.textContaining('Sáb'), findsNothing);
    expect(find.textContaining('Dom'), findsNothing);
    expect(find.textContaining('236,00'), findsOneWidget);
  });

  testWidgets('al bajar carga la página siguiente', (tester) async {
    final source = FakeHistory(businessDays(45));
    await pumpHistory(tester, source);
    expect(source.asked, [null]);

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();

    expect(source.asked, hasLength(2));
    expect(source.asked.last, businessDays(30).last.valueDate);
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(find.text('No hay tasas anteriores.'), findsOneWidget);
  });

  testWidgets('el calendario salta a la tasa vigente en esa fecha', (
    tester,
  ) async {
    final source = FakeHistory(businessDays(30));
    await pumpHistory(tester, source);

    await tester.tap(find.byTooltip('Ir a una fecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15')); // domingo
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    // Pide las anteriores al lunes 16: la primera es el viernes 13.
    expect(source.asked.last, DateTime(2026, 11, 16));
    expect(find.text('Desde el 15 de noviembre de 2026'), findsOneWidget);
    final first = tester.widget<PublicationCard>(
      find.byType(PublicationCard).first,
    );
    expect(first.publication.valueDate, DateTime(2026, 11, 13));
    expect(find.text('Vigente'), findsNothing);

    await tester.tap(find.text('Ver recientes'));
    await tester.pumpAndSettle();
    expect(source.asked.last, isNull);
    expect(find.text('Vigente'), findsOneWidget);
  });

  testWidgets('tocar una tasa la copia', (tester) async {
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
    await pumpHistory(tester, FakeHistory(businessDays(3)));

    await tester.tap(find.textContaining('236,50').first);
    await tester.pumpAndSettle();
    expect(copied, '236,50');
  });

  testWidgets('un error se puede reintentar', (tester) async {
    final source = FakeHistory(businessDays(3))
      ..error = const RateFetchException('Sin conexión a internet.');
    await pumpHistory(tester, source);
    expect(find.text('Sin conexión a internet.'), findsOneWidget);

    source.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicationCard), findsNWidgets(3));
  });
}
