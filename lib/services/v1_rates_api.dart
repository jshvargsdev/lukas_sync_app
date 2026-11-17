import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/bcv_publication.dart';
import '../models/rates.dart';
import 'rate_source.dart';

/// URL base de la API v1 (ver docs/api-v1.md). No está en el repo: se pasa
/// al compilar con `--dart-define-from-file=config/prod.json` (ver README).
const String kRatesApiBaseUrl = String.fromEnvironment('RATES_API_BASE_URL');

/// Historial de publicaciones del BCV.
abstract class RateHistorySource {
  /// Publicaciones con fecha valor anterior a [before] (o las más recientes
  /// si es null), de la más nueva a la más vieja.
  Future<BcvHistoryPage> bcvHistory({DateTime? before, int limit});
}

/// Cliente de la API v1: tasas actuales e historial del BCV. Sin token: los
/// endpoints de lectura son públicos.
class V1RatesApi implements RateSource, RateHistorySource {
  final Uri _base;
  final http.Client _client;

  V1RatesApi({required String baseUrl, http.Client? client})
    : _base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
      _client = client ?? http.Client();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<Rates> fetchRates() async {
    final json = await _getJson(_base.resolve('v1/rates/latest'));
    try {
      return ratesFromV1Json(json);
    } catch (_) {
      throw const RateFetchException(
        'El servicio de tasas devolvió datos inválidos.',
      );
    }
  }

  @override
  Future<BcvHistoryPage> bcvHistory({DateTime? before, int limit = 30}) async {
    final uri = _base
        .resolve('v1/rates/bcv/history')
        .replace(
          queryParameters: {
            'limit': '$limit',
            if (before != null) 'before': _dateFormat.format(before),
          },
        );
    final json = await _getJson(uri);
    try {
      return BcvHistoryPage.fromJson(json);
    } catch (_) {
      throw const RateFetchException(
        'El servicio de tasas devolvió datos inválidos.',
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    if (!_base.hasScheme) {
      throw const RateFetchException(
        'La app no tiene configurado el servicio de tasas.',
      );
    }
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const RateFetchException('El servicio de tasas tardó demasiado.');
    } on http.ClientException {
      throw const RateFetchException('Sin conexión a internet.');
    }

    if (response.statusCode == 503) {
      throw const RateFetchException(
        'Las tasas del BCV no están disponibles por ahora.',
      );
    }
    if (response.statusCode == 400) {
      throw const RateFetchException('La fecha elegida no es válida.');
    }
    if (response.statusCode != 200) {
      throw RateFetchException(
        'El servicio de tasas no respondió (código ${response.statusCode}).',
      );
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const RateFetchException(
        'El servicio de tasas devolvió datos inválidos.',
      );
    }
  }
}

/// Convierte `/v1/rates/latest` en [Rates]. Si Binance falló (`usdt: null`),
/// el USDT queda en 0 y la app lo muestra como no disponible.
Rates ratesFromV1Json(Map<String, dynamic> json) {
  final bcv = json['bcv'] as Map<String, dynamic>;
  final usdt = json['usdt'] as Map<String, dynamic>?;
  final bcvAt = DateTime.parse(bcv['fetchedAt'] as String).toLocal();
  final usdtAt = usdt == null
      ? null
      : DateTime.tryParse('${usdt['fetchedAt']}')?.toLocal();
  final usd = Rates.parseRate(bcv['usd']);
  final eur = Rates.parseRate(bcv['eur']);
  if (usd <= 0 || eur <= 0) throw const FormatException('BCV inválido');
  return Rates(
    dolarBcv: usd,
    euroBcv: eur,
    usdtBinance: usdt == null ? 0 : Rates.parseRate(usdt['value']),
    // "Actualizado" refleja el dato más reciente de los dos.
    fetchedAt: usdtAt != null && usdtAt.isAfter(bcvAt) ? usdtAt : bcvAt,
  );
}
