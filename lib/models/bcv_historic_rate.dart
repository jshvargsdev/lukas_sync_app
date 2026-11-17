import 'rates.dart';

/// Tasa BCV vigente en [date]. [valueDate] es la fecha valor de la
/// publicación que aplica: en fines de semana y feriados es anterior a [date].
class BcvHistoricRate {
  final DateTime date;
  final DateTime valueDate;
  final double usd;
  final double eur;

  const BcvHistoricRate({
    required this.date,
    required this.valueDate,
    required this.usd,
    required this.eur,
  });

  bool get isFromEarlierDay => valueDate.isBefore(date);

  factory BcvHistoricRate.fromJson(Map<String, dynamic> json) {
    final usd = Rates.parseRate(json['usd']);
    final eur = Rates.parseRate(json['eur']);
    if (usd <= 0 || eur <= 0) throw const FormatException('Tasa inválida');
    return BcvHistoricRate(
      date: DateTime.parse(json['date'] as String),
      valueDate: DateTime.parse(json['valueDate'] as String),
      usd: usd,
      eur: eur,
    );
  }
}
