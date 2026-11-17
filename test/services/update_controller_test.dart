import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lukas_sync_app/domain/app_release.dart';
import 'package:lukas_sync_app/services/update_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePlatform extends UpdatePlatform {
  final String dir;
  FakePlatform(this.dir);

  @override
  Future<List<String>> supportedAbis() async => ['arm64-v8a', 'armeabi-v7a'];
  @override
  Future<String> downloadDir() async => dir;
}

Map<String, dynamic> releaseJson(String tag) => {
  'tag_name': tag,
  'body': 'Novedades',
  'assets': [
    {
      'name': 'app-arm64-v8a-release.apk',
      'browser_download_url': 'https://example.test/arm64.apk',
      'size': 4,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late int calls;
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 17, 10);
    calls = 0;
    tmp = await Directory.systemTemp.createTemp('lukas_update_test');
  });

  tearDown(() => tmp.delete(recursive: true));

  UpdateController build({
    String latest = 'v2.1.0',
    int status = 200,
    bool enabled = true,
    http.Client? client,
  }) {
    return UpdateController(
      currentVersion: '2.0.0',
      enabled: enabled,
      platform: FakePlatform(tmp.path),
      now: () => now,
      client:
          client ??
          MockClient((req) async {
            calls++;
            expect(req.url.toString(), kReleasesUrl);
            return http.Response(jsonEncode(releaseJson(latest)), status);
          }),
    );
  }

  test('avisa solo si la versión publicada es más nueva', () async {
    final newer = build();
    expect(await newer.check(force: true), isNotNull);
    expect(newer.showBanner, isTrue);

    final same = build(latest: 'v2.0.0');
    expect(await same.check(force: true), isNull);
    expect(same.showBanner, isFalse);
  });

  test('consulta como máximo cada 6 horas, salvo que se fuerce', () async {
    final c = build();
    await c.check();
    await c.check();
    expect(calls, 1);

    now = now.add(const Duration(hours: 5));
    await c.check();
    expect(calls, 1);
    await c.check(force: true);
    expect(calls, 2);

    now = now.add(kUpdateCheckInterval);
    await c.check();
    expect(calls, 3);
  });

  test('en segundo plano los errores se ignoran; a mano se informan', () async {
    final c = build(status: 500);
    expect(await c.check(), isNull);
    await expectLater(
      c.check(force: true),
      throwsA(
        isA<UpdateException>().having(
          (e) => e.message,
          'message',
          'No se pudo consultar si hay versiones nuevas (código 500).',
        ),
      ),
    );
    final none = build(status: 404);
    await expectLater(
      none.check(force: true),
      throwsA(
        isA<UpdateException>().having(
          (e) => e.message,
          'message',
          'Todavía no hay versiones publicadas.',
        ),
      ),
    );
  });

  test(
    'al reabrir la app antes de 6 h el aviso sigue, sin consultar',
    () async {
      await build().start();
      expect(calls, 1);

      now = now.add(const Duration(hours: 1));
      final reopened = build();
      await reopened.start();
      expect(calls, 1);
      expect(reopened.showBanner, isTrue);
      expect(reopened.available!.version, '2.1.0');
    },
  );

  test('tras actualizar la app ya no avisa de esa versión', () async {
    await build().start();
    final updated = UpdateController(
      currentVersion: '2.1.0',
      enabled: true,
      platform: FakePlatform(tmp.path),
      now: () => now,
      client: MockClient((_) async => http.Response('', 500)),
    );
    await updated.start();
    expect(updated.showBanner, isFalse);
  });

  test('al arrancar borra los APK descargados antes', () async {
    final old = File('${tmp.path}/app-arm64-v8a-release.apk')
      ..writeAsBytesSync([1, 2, 3]);
    final other = File('${tmp.path}/nota.txt')..writeAsStringSync('x');
    await build().start();
    expect(old.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
  });

  test('deshabilitado (debug) no consulta nada', () async {
    final c = build(enabled: false);
    await c.start();
    expect(await c.check(force: true), isNull);
    expect(calls, 0);
  });

  test(
    'ocultar una versión la recuerda; una más nueva vuelve a avisar',
    () async {
      final c = build();
      await c.check(force: true);
      await c.dismiss();
      expect(c.showBanner, isFalse);

      // Otra sesión de la app con la misma versión publicada.
      final again = build();
      await again.start();
      expect(again.showBanner, isFalse);

      // Pasado el intervalo se publica una más nueva.
      now = now.add(kUpdateCheckInterval);
      final next = build(latest: 'v2.2.0');
      await next.start();
      expect(next.showBanner, isTrue);
    },
  );

  test('descarga el APK de este teléfono informando el avance', () async {
    final c = build(
      client: MockClient.streaming((req, _) async {
        if (req.url.host == 'api.github.com') {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(releaseJson('v2.1.0')))),
            200,
          );
        }
        expect(req.url.toString(), 'https://example.test/arm64.apk');
        return http.StreamedResponse(
          Stream.fromIterable([
            [1, 2],
            [3, 4],
          ]),
          200,
          contentLength: 4,
        );
      }),
    );
    final release = (await c.check(force: true))!;
    final asset = await c.assetFor(release);
    final progress = <double>[];
    final path = await c.download(asset, onProgress: progress.add);

    expect(progress, [0.5, 1.0]);
    expect(await File(path).readAsBytes(), [1, 2, 3, 4]);
  });

  test('una descarga incompleta falla y no deja el archivo', () async {
    final c = build(
      client: MockClient.streaming(
        (req, _) async => http.StreamedResponse(Stream.value([1, 2]), 200),
      ),
    );
    final asset = ReleaseAsset(
      name: 'app-arm64-v8a-release.apk',
      url: Uri.parse('https://example.test/arm64.apk'),
      size: 4,
    );
    await expectLater(
      c.download(asset, onProgress: (_) {}),
      throwsA(isA<UpdateException>()),
    );
    expect(File('${tmp.path}/${asset.name}').existsSync(), isFalse);
  });
}
