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
