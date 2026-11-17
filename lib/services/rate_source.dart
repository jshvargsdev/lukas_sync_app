import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/rates.dart';

/// Error al obtener tasas, con un mensaje listo para mostrar al usuario.
class RateFetchException implements Exception {
  final String message;
  const RateFetchException(this.message);

  @override
  String toString() => message;
}

/// Origen de las tasas oficiales. Aísla a la app de la API concreta para que
/// cambiar de proveedor solo requiera una nueva implementación.
abstract class RateSource {
  Future<Rates> fetchRates();
}

class ApiRateSource implements RateSource {
  final http.Client _client;

  ApiRateSource({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<Rates> fetchRates() async {
    final url = dotenv.env['RATES_API_URL'];
    final token = dotenv.env['RATES_API_TOKEN'];
    if (url == null || url.isEmpty || token == null || token.isEmpty) {
      throw const RateFetchException(
        'La app no tiene configurado el servicio de tasas.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const RateFetchException('El servicio de tasas tardó demasiado.');
    } on http.ClientException {
      throw const RateFetchException('Sin conexión a internet.');
    }

    if (response.statusCode != 200) {
      throw RateFetchException(
        'El servicio de tasas no respondió (código ${response.statusCode}).',
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['ok'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      return Rates.fromApiData(body['data'] as Map<String, dynamic>);
    } catch (_) {
      throw const RateFetchException(
        'El servicio de tasas devolvió datos inválidos.',
      );
    }
  }
}
