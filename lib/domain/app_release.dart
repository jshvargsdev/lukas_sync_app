/// Compara versiones `X.Y.Z` (acepta prefijo `v` y sufijo `+build`, que se
/// ignora). Devuelve <0 si [a] es menor, 0 si son iguales y >0 si es mayor.
/// Las partes que no son números cuentan como 0.
int compareVersions(String a, String b) {
  List<int> parts(String v) {
    final core = v.trim().replaceFirst(RegExp('^[vV]'), '').split('+').first;
    return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// Un APK adjunto a un release.
class ReleaseAsset {
  final String name;
  final Uri url;
  final int size;

  const ReleaseAsset({
    required this.name,
    required this.url,
    required this.size,
  });
}

/// Release de GitHub con los APK de una versión.
class AppRelease {
  /// Versión sin la `v`: "2.1.0".
  final String version;
  final String notes;
  final List<ReleaseAsset> assets;

  const AppRelease({
    required this.version,
    required this.notes,
    required this.assets,
  });

  /// Respuesta de `GET /repos/{owner}/{repo}/releases/latest`.
  factory AppRelease.fromGitHubJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String;
    return AppRelease(
      version: tag.replaceFirst(RegExp('^[vV]'), ''),
      notes: (json['body'] as String? ?? '').trim(),
      assets: [
        for (final a in (json['assets'] as List<dynamic>? ?? const []))
          ReleaseAsset(
            name: (a as Map<String, dynamic>)['name'] as String,
            url: Uri.parse(a['browser_download_url'] as String),
            size: (a['size'] as num?)?.toInt() ?? 0,
          ),
      ],
    );
  }

  /// APK para el primer ABI soportado por el teléfono que tenga uno
  /// publicado (`app-<abi>-release.apk`, como lo genera --split-per-abi).
  /// Si no hay ninguno por ABI, usa el universal `app-release.apk`.
  ReleaseAsset? apkFor(List<String> supportedAbis) {
    ReleaseAsset? named(String n) =>
        assets.where((a) => a.name == n).firstOrNull;
    for (final abi in supportedAbis) {
      final a = named('app-$abi-release.apk');
      if (a != null) return a;
    }
    return named('app-release.apk');
  }
}
