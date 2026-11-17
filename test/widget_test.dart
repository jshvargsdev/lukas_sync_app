import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukas_sync_app/main.dart';
import 'package:lukas_sync_app/services/rates_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_rate_source.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es_VE');
  });

  testWidgets('La app arranca y muestra el título', (tester) async {
    ratesController = RatesController(
      source: FakeRateSource(next: sampleRates()),
      settings: appSettings,
    );
    await tester.pumpWidget(const LukasSyncApp());
    await tester.runAsync(ratesController.refresh);
    await tester.pump();
    expect(find.text('Lukas Sync'), findsOneWidget);
  });
}
