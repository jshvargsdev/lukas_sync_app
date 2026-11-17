import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/custom_rates_store.dart';
import 'services/home_widget_sync.dart';
import 'services/rates_controller.dart';
import 'services/update_controller.dart';
import 'services/v1_rates_api.dart';
import 'theme/app_theme.dart';

final AppSettings appSettings = AppSettings();

/// Actualizador. Se reemplaza en main() con la versión instalada; deshabilitado
/// en debug y fuera de Android.
UpdateController updateController = UpdateController(
  currentVersion: '0.0.0',
  enabled: false,
);
final CustomRatesStore customRatesStore = CustomRatesStore();

final V1RatesApi _api = V1RatesApi(baseUrl: kRatesApiBaseUrl);

/// Historial del BCV. Se reasigna en los tests.
RateHistorySource rateHistorySource = _api;

/// Se reasigna en los tests para usar una fuente de tasas falsa.
RatesController ratesController = RatesController(
  source: _api,
  onRatesFetched: pushRatesToWidget,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _applyOrientationPolicy();
  await initializeDateFormatting('es_VE', null);
  await appSettings.load();
  await customRatesStore.load();
  final info = await PackageInfo.fromPlatform();
  updateController = UpdateController(
    currentVersion: info.version,
    enabled: kReleaseMode && defaultTargetPlatform == TargetPlatform.android,
  );
  runApp(const LukasSyncApp());
  ratesController.start();
  scheduleWidgetRefresh();
  updateController.start();
}

Future<void> _applyOrientationPolicy() async {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  final isTablet = size.shortestSide >= 600;
  await SystemChrome.setPreferredOrientations(
    isTablet
        ? const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : const [DeviceOrientation.portraitUp],
  );
}

class LukasSyncApp extends StatelessWidget {
  const LukasSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Lukas Sync',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: appSettings.themeMode,
          locale: const Locale('es', 'VE'),
          supportedLocales: const [Locale('es', 'VE'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const HomeScreen(),
        );
      },
    );
  }
}
