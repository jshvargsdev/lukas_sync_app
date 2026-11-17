import 'package:lukas_sync_app/models/rates.dart';
import 'package:lukas_sync_app/services/rate_source.dart';

/// Fuente de tasas controlable desde los tests.
class FakeRateSource implements RateSource {
  Rates? next;
  RateFetchException? error;
  int calls = 0;

  FakeRateSource({this.next, this.error});

  @override
  Future<Rates> fetchRates() async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return next!;
  }
}

Rates sampleRates({DateTime? at}) => Rates(
  dolarBcv: 36.5123,
  euroBcv: 39.8,
  usdtBinance: 40,
  fetchedAt: at ?? DateTime(2026, 11, 17, 9, 30),
);
