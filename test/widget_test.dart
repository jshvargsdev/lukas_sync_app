import 'package:flutter_test/flutter_test.dart';

import 'package:lukas_sync_app/main.dart';

void main() {
  testWidgets('La app arranca y muestra el título', (tester) async {
    await tester.pumpWidget(const LukasSyncApp());
    await tester.pump();
    expect(find.text('Lukas Sync'), findsOneWidget);
  });
}
