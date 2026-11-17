import 'rates.dart';

/// Una publicación del BCV: tasas con su fecha valor.
class BcvPublication {
  final DateTime valueDate;
  final double usd;
  final double eur;

  const BcvPublication({
    required this.valueDate,
    required this.usd,
    required this.eur,
  });

  factory BcvPublication.fromJson(Map<String, dynamic> json) {
    final usd = Rates.parseRate(json['usd']);
    final eur = Rates.parseRate(json['eur']);
    if (usd <= 0 || eur <= 0) throw const FormatException('Tasa inválida');
    return BcvPublication(
      valueDate: DateTime.parse(json['valueDate'] as String),
      usd: usd,
      eur: eur,
    );
  }
}

/// Página del historial, de la publicación más reciente a la más antigua.
class BcvHistoryPage {
  final List<BcvPublication> items;

  /// Valor de `before` para pedir la página siguiente; null si no hay más.
  final DateTime? nextBefore;

  const BcvHistoryPage({required this.items, required this.nextBefore});

  factory BcvHistoryPage.fromJson(Map<String, dynamic> json) {
    final next = json['nextBefore'];
    return BcvHistoryPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => BcvPublication.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextBefore: next == null ? null : DateTime.parse(next as String),
    );
  }
}
