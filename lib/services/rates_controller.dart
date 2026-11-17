import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rates.dart';
import 'rate_source.dart';

const _kRatesCacheKey = '@lukas_rates_cache';

/// Cada cuánto se refrescan las tasas con la app abierta.
const Duration kRefreshInterval = Duration(hours: 1);

/// A partir de cuánto tiempo se consideran viejos los datos mostrados.
const Duration kStaleAfter = Duration(hours: 2);

/// Estado de las tasas oficiales: carga, caché, refresco periódico y errores.
///
/// El refresco periódico se pausa con la app en segundo plano y, al volver,
/// se refresca de inmediato si ya pasó [kRefreshInterval].
class RatesController extends ChangeNotifier with WidgetsBindingObserver {
  final RateSource _source;
  final DateTime Function() _now;

  /// Se llama cada vez que llegan tasas nuevas desde la red.
  final void Function(Rates rates)? onRatesFetched;

  RatesController({
    required RateSource source,
    DateTime Function()? now,
    this.onRatesFetched,
  }) : _source = source,
       _now = now ?? DateTime.now;

  Rates? _rates;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastAttempt;
  Timer? _timer;
  bool _started = false;

  Rates? get rates => _rates;
  bool get hasRates => _rates != null;
  bool get isLoading => _isLoading;

  /// Mensaje del último intento fallido; null si el último intento funcionó.
  String? get errorMessage => _errorMessage;

  bool get isStale {
    final r = _rates;
    if (r == null || _isLoading) return false;
    return _now().difference(r.fetchedAt) > kStaleAfter;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await _loadCache();
    _scheduleTimer();
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _lastAttempt = _now();
    notifyListeners();
    try {
      final fresh = await _source.fetchRates();
      _rates = fresh;
      _errorMessage = null;
      await _saveCache(fresh);
      onRatesFetched?.call(fresh);
    } on RateFetchException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('Error inesperado obteniendo tasas: $e');
      _errorMessage = 'No se pudieron actualizar las tasas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        final last = _lastAttempt;
        if (last == null || _now().difference(last) >= kRefreshInterval) {
          refresh();
        }
        _scheduleTimer();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _scheduleTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(kRefreshInterval, (_) => refresh());
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRatesCacheKey);
      if (raw == null) return;
      final cached = Rates.fromCacheJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (cached == null) return;
      _rates = cached;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando caché de tasas: $e');
    }
  }

  Future<void> _saveCache(Rates rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRatesCacheKey, jsonEncode(rates.toCacheJson()));
    } catch (e) {
      debugPrint('Error guardando caché de tasas: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
