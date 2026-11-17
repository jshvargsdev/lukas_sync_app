import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_release.dart';

const _kLastCheckKey = '@lukas_update_last_check';
const _kDismissedKey = '@lukas_update_dismissed';

/// Último release consultado (JSON de GitHub), para que el aviso siga al
/// reabrir la app aunque no toque volver a consultar.
const _kLatestKey = '@lukas_update_latest';

/// Cada cuánto se consulta GitHub como máximo (límite: 60 consultas/hora por IP).
const Duration kUpdateCheckInterval = Duration(hours: 6);

const String kReleasesUrl =
    'https://api.github.com/repos/jshvargsdev/lukas_sync_app/releases/latest';

/// Error del actualizador con un mensaje listo para el usuario.
class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);

  @override
  String toString() => message;
}

/// Operaciones nativas de Android (ver MainActivity.kt).
class UpdatePlatform {
  static const _channel = MethodChannel('lukas_sync/updater');

  Future<List<String>> supportedAbis() async =>
      (await _channel.invokeListMethod<String>('supportedAbis')) ?? const [];
  Future<String> downloadDir() async =>
      (await _channel.invokeMethod<String>('downloadDir'))!;
  Future<bool> canInstall() async =>
      (await _channel.invokeMethod<bool>('canInstall')) ?? false;
  Future<void> openInstallSettings() =>
      _channel.invokeMethod('openInstallSettings');
  Future<void> installApk(String path) =>
      _channel.invokeMethod('installApk', {'path': path});
}

/// Busca versiones nuevas en GitHub Releases, las descarga y abre el
/// instalador. Las actualizaciones son opcionales: se pueden ocultar por
/// versión.
class UpdateController extends ChangeNotifier with WidgetsBindingObserver {
  final String currentVersion;
  final UpdatePlatform _platform;
  final http.Client _client;
  final DateTime Function() _now;

  /// false en debug: un APK de release no se instala sobre uno de debug.
  final bool enabled;

  UpdateController({
    required this.currentVersion,
    required this.enabled,
    UpdatePlatform? platform,
    http.Client? client,
    DateTime Function()? now,
  }) : _platform = platform ?? UpdatePlatform(),
       _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  AppRelease? _available;
  String? _dismissed;
  bool _checking = false;
  bool _started = false;

  /// Release más nuevo que la versión instalada, si lo hay.
  AppRelease? get available => _available;

  /// Mostrar el aviso en el Home: hay versión nueva y no se ocultó.
  bool get showBanner =>
      _available != null && _available!.version != _dismissed;

  Future<void> start() async {
    if (!enabled || _started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    _dismissed = prefs.getString(_kDismissedKey);
    final cached = prefs.getString(_kLatestKey);
    if (cached != null) {
      try {
        _setLatest(
          AppRelease.fromGitHubJson(jsonDecode(cached) as Map<String, dynamic>),
        );
      } catch (_) {
        await prefs.remove(_kLatestKey);
      }
    }
    await check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  /// Consulta GitHub. Sin [force] respeta [kUpdateCheckInterval] y no
  /// lanza errores (es una consulta de fondo). Con [force] siempre consulta
  /// y lanza [UpdateException] si falla.
  Future<AppRelease?> check({bool force = false}) async {
    if (!enabled || _checking) return _available;
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString(_kLastCheckKey) ?? '');
    if (!force &&
        last != null &&
        _now().difference(last) < kUpdateCheckInterval) {
      return _available;
    }

    _checking = true;
    try {
      final (release, raw) = await _fetchLatest();
      await prefs.setString(_kLastCheckKey, _now().toIso8601String());
      await prefs.setString(_kLatestKey, raw);
      _setLatest(release);
      return _available;
    } on UpdateException {
      if (force) rethrow;
      return _available;
    } finally {
      _checking = false;
    }
  }

  void _setLatest(AppRelease release) {
    _available = compareVersions(release.version, currentVersion) > 0
        ? release
        : null;
    notifyListeners();
  }

  Future<(AppRelease, String)> _fetchLatest() async {
    final http.Response res;
    try {
      res = await _client
          .get(
            Uri.parse(kReleasesUrl),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'LukasSync',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const UpdateException('GitHub tardó demasiado en responder.');
    } on http.ClientException {
      throw const UpdateException('Sin conexión a internet.');
    }
    if (res.statusCode == 404) {
      throw const UpdateException('Todavía no hay versiones publicadas.');
    }
    if (res.statusCode != 200) {
      throw UpdateException(
        'No se pudo consultar si hay versiones nuevas (código ${res.statusCode}).',
      );
    }
    try {
      final release = AppRelease.fromGitHubJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
      return (release, res.body);
    } catch (_) {
      throw const UpdateException('La información de la versión es inválida.');
    }
  }

  /// Oculta el aviso de esta versión; la siguiente volverá a avisar.
  Future<void> dismiss() async {
    final v = _available?.version;
    if (v == null) return;
    _dismissed = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedKey, v);
  }

  /// APK que corresponde a este teléfono.
  Future<ReleaseAsset> assetFor(AppRelease release) async {
    final asset = release.apkFor(await _platform.supportedAbis());
    if (asset == null) {
      throw const UpdateException(
        'Esta versión no tiene un APK para tu teléfono.',
      );
    }
    return asset;
  }

  Future<bool> canInstall() => _platform.canInstall();
  Future<void> openInstallSettings() => _platform.openInstallSettings();

  /// Descarga el APK e informa el avance (0..1) en [onProgress].
  Future<String> download(
    ReleaseAsset asset, {
    required void Function(double progress) onProgress,
  }) async {
    final dir = await _platform.downloadDir();
    final file = File('$dir/${asset.name}');
    try {
      return await _downloadTo(file, asset, onProgress);
    } catch (_) {
      // No dejar un APK a medias en el teléfono.
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<String> _downloadTo(
    File file,
    ReleaseAsset asset,
    void Function(double progress) onProgress,
  ) async {
    try {
      final res = await _client
          .send(http.Request('GET', asset.url))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        throw UpdateException(
          'No se pudo descargar la actualización (código ${res.statusCode}).',
        );
      }
      final total = res.contentLength ?? asset.size;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in res.stream.timeout(
          const Duration(seconds: 30),
        )) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress(received / total);
        }
      } finally {
        await sink.close();
      }
      if (asset.size > 0 && received != asset.size) {
        throw const UpdateException(
          'La descarga quedó incompleta. Intenta de nuevo.',
        );
      }
      return file.path;
    } on TimeoutException {
      throw const UpdateException(
        'La descarga se detuvo. Revisa tu conexión e intenta de nuevo.',
      );
    } on http.ClientException {
      throw const UpdateException('Sin conexión a internet.');
    } on FileSystemException {
      throw const UpdateException(
        'No hay espacio para descargar la actualización.',
      );
    }
  }

  Future<void> install(String path) => _platform.installApk(path);

  @override
  void dispose() {
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
