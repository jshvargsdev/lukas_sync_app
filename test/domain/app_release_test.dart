import 'package:flutter_test/flutter_test.dart';
import 'package:lukas_sync_app/domain/app_release.dart';

void main() {
  group('compareVersions', () {
    test('compara número a número, no como texto', () {
      expect(compareVersions('2.0.10', '2.0.9'), greaterThan(0));
      expect(compareVersions('2.1.0', '2.0.99'), greaterThan(0));
      expect(compareVersions('1.9.0', '2.0.0'), lessThan(0));
    });

    test('ignora la v, el build y las partes faltantes', () {
      expect(compareVersions('v2.1.0', '2.1.0'), 0);
      expect(compareVersions('2.1.0+5', '2.1.0+3'), 0);
      expect(compareVersions('2.1', '2.1.0'), 0);
      expect(compareVersions('V3', '2.9.9'), greaterThan(0));
    });
  });

  group('AppRelease', () {
    final json = {
      'tag_name': 'v2.1.0',
      'body': '  - Actualizaciones desde la app\n',
      'assets': [
        {
          'name': 'app-armeabi-v7a-release.apk',
          'browser_download_url': 'https://example.test/v7a.apk',
          'size': 20697240,
        },
        {
          'name': 'app-arm64-v8a-release.apk',
          'browser_download_url': 'https://example.test/arm64.apk',
          'size': 23219076,
        },
      ],
    };

    test('lee versión, notas y APK del release de GitHub', () {
      final r = AppRelease.fromGitHubJson(json);
      expect(r.version, '2.1.0');
      expect(r.notes, '- Actualizaciones desde la app');
      expect(r.assets, hasLength(2));
      expect(r.assets.last.size, 23219076);
    });

    test('elige el APK del primer ABI soportado que esté publicado', () {
      final r = AppRelease.fromGitHubJson(json);
      expect(
        r.apkFor(['arm64-v8a', 'armeabi-v7a', 'armeabi'])!.name,
        'app-arm64-v8a-release.apk',
      );
      expect(
        r.apkFor(['x86_64', 'armeabi-v7a'])!.name,
        'app-armeabi-v7a-release.apk',
      );
      expect(r.apkFor(['x86']), isNull);
    });

    test('si no hay APK por ABI usa el universal', () {
      final r = AppRelease.fromGitHubJson({
        'tag_name': '2.1.0',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://example.test/all.apk',
          },
        ],
      });
      expect(r.apkFor(['arm64-v8a'])!.name, 'app-release.apk');
      expect(r.notes, isEmpty);
    });
  });
}
