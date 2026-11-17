import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';

import '../domain/converter.dart';
import '../models/rates.dart';
import 'rate_source.dart';

/// Clase nativa del widget (android/app/src/main/kotlin/.../RatesWidgetProvider.kt).
const String kWidgetProvider = 'com.joshuavargas.lukassync.RatesWidgetProvider';

const String _kRefreshTaskName = 'lukas-refresh-widget';

/// Claves compartidas con RatesWidgetProvider.kt.
abstract final class WidgetKeys {
  static const usd = 'widget_usd';
  static const eur = 'widget_eur';
  static const usdt = 'widget_usdt';
}

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Datos que muestra el widget, ya formateados.
Map<String, String> widgetDataFor(Rates r) => {
  WidgetKeys.usd: formatRate(r.dolarBcv),
  WidgetKeys.eur: formatRate(r.euroBcv),
  WidgetKeys.usdt: formatRate(r.usdtBinance),
};

/// Guarda las tasas para el widget y le pide que se redibuje.
Future<void> pushRatesToWidget(Rates rates) async {
  if (!_isAndroid) return;
  try {
    for (final e in widgetDataFor(rates).entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: kWidgetProvider);
  } catch (e) {
    debugPrint('Error actualizando el widget: $e');
  }
}

/// Registra la descarga horaria en segundo plano que mantiene el widget al
/// día aunque la app no se abra. Android decide el momento exacto (puede
/// retrasarla para ahorrar batería) y solo corre con conexión.
Future<void> scheduleWidgetRefresh() async {
  if (!_isAndroid) return;
  try {
    await Workmanager().initialize(widgetRefreshDispatcher);
    await Workmanager().registerPeriodicTask(
      _kRefreshTaskName,
      _kRefreshTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint('Error programando la actualización del widget: $e');
  }
}

/// Punto de entrada del isolate de segundo plano de workmanager.
@pragma('vm:entry-point')
void widgetRefreshDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
      await initializeDateFormatting('es_VE', null);
      final rates = await ApiRateSource().fetchRates();
      await pushRatesToWidget(rates);
      return true;
    } catch (e) {
      debugPrint('Error refrescando el widget en segundo plano: $e');
      // false = workmanager reintenta más tarde con backoff.
      return false;
    }
  });
}
