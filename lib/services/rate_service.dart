import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Rates {
  final String dolarBcv;
  final String euroBcv;
  final String usdtBinance;
  final DateTime fetchedAt;

  const Rates({
    required this.dolarBcv,
    required this.euroBcv,
    required this.usdtBinance,
    required this.fetchedAt,
  });
}

class RateService {
  Future<Rates> fetchRates() async {
    final url = dotenv.env['RATES_API_URL'];
    final token = dotenv.env['RATES_API_TOKEN'];
    if (url == null || url.isEmpty) {
      throw StateError('RATES_API_URL no configurado en .env');
    }
    if (token == null || token.isEmpty) {
      throw StateError('RATES_API_TOKEN no configurado en .env');
    }

    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Error API tasas: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['ok'] != true || body['data'] is! Map) {
      throw Exception('Respuesta inválida de la API');
    }

    final data = body['data'] as Map<String, dynamic>;
    final bcv = data['bcv'] as Map<String, dynamic>;
    final binance = data['binance'] as Map<String, dynamic>;
    final dollar = bcv['dollar'] as Map<String, dynamic>;
    final euro = bcv['euro'] as Map<String, dynamic>;

    String fmt(dynamic v) => (v is num ? v : double.tryParse('$v') ?? 0)
        .toDouble()
        .toStringAsFixed(2);

    final fetchedAt =
        DateTime.tryParse('${data['fetchedAt']}')?.toLocal() ?? DateTime.now();

    return Rates(
      dolarBcv: fmt(dollar['value']),
      euroBcv: fmt(euro['value']),
      usdtBinance: fmt(binance['value']),
      fetchedAt: fetchedAt,
    );
  }
}
