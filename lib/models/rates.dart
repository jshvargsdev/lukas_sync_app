/// Tasas oficiales expresadas en bolívares por unidad de moneda.
class Rates {
  final double dolarBcv;
  final double euroBcv;
  final double usdtBinance;
  final DateTime fetchedAt;

  const Rates({
    required this.dolarBcv,
    required this.euroBcv,
    required this.usdtBinance,
    required this.fetchedAt,
  });

  /// Construye las tasas desde el bloque `data` de la API.
  factory Rates.fromApiData(Map<String, dynamic> data) {
    final bcv = data['bcv'] as Map<String, dynamic>;
    final binance = data['binance'] as Map<String, dynamic>;
    final dollar = bcv['dollar'] as Map<String, dynamic>;
    final euro = bcv['euro'] as Map<String, dynamic>;
    return Rates(
      dolarBcv: parseRate(dollar['value']),
      euroBcv: parseRate(euro['value']),
      usdtBinance: parseRate(binance['value']),
      fetchedAt:
          DateTime.tryParse('${data['fetchedAt']}')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Lee la caché local. Acepta el formato de la v1, que guardaba las tasas
  /// como strings con 2 decimales, y el actual, que las guarda como números.
  static Rates? fromCacheJson(Map<String, dynamic> json) {
    final ts = DateTime.tryParse('${json['fetchedAt']}');
    if (ts == null) return null;
    return Rates(
      dolarBcv: parseRate(json['dolarBcv']),
      euroBcv: parseRate(json['euroBcv']),
      usdtBinance: parseRate(json['usdtBinance']),
      fetchedAt: ts.toLocal(),
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'dolarBcv': dolarBcv,
    'euroBcv': euroBcv,
    'usdtBinance': usdtBinance,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
  };

  /// Convierte un valor numérico o textual en tasa. Devuelve 0 si no es válido.
  static double parseRate(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
