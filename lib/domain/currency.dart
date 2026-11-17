import '../models/custom_rate.dart';
import '../models/rates.dart';

const String kVesId = 'VES';
const String kUsdId = 'USD';
const String kEurId = 'EUR';
const String kUsdtId = 'USDT';

const Set<String> kOfficialIds = {kVesId, kUsdId, kEurId, kUsdtId};

/// Una moneda que se puede convertir: oficial o personalizada.
class CurrencyOption {
  final String id;
  final String name;
  final String icon;

  /// Bolívares por unidad. El bolívar vale 1.
  final double rateInVes;

  /// Tasa personalizada de origen, si aplica.
  final CustomRate? custom;

  const CurrencyOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.rateInVes,
    this.custom,
  });

  bool get isVes => id == kVesId;
  bool get isCustom => custom != null;
}

/// Lista ordenada de monedas: VES, oficiales y luego las personalizadas.
List<CurrencyOption> buildCurrencyOptions({
  required Rates? rates,
  required List<CustomRate> customRates,
}) {
  return [
    const CurrencyOption(
      id: kVesId,
      name: 'Bolívares',
      icon: '🇻🇪',
      rateInVes: 1,
    ),
    CurrencyOption(
      id: kUsdId,
      name: 'Dólar BCV',
      icon: '🇺🇸',
      rateInVes: rates?.dolarBcv ?? 0,
    ),
    CurrencyOption(
      id: kEurId,
      name: 'Euro BCV',
      icon: '🇪🇺',
      rateInVes: rates?.euroBcv ?? 0,
    ),
    CurrencyOption(
      id: kUsdtId,
      name: 'USDT Binance',
      icon: '₮',
      rateInVes: rates?.usdtBinance ?? 0,
    ),
    for (final r in customRates)
      CurrencyOption(
        id: r.id,
        name: r.name,
        icon: r.icon,
        rateInVes: Rates.parseRate(r.value),
        custom: r,
      ),
  ];
}
