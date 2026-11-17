import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/custom_rates_store.dart';
import 'services/rate_source.dart';
import 'services/rates_controller.dart';

final AppSettings appSettings = AppSettings();
final CustomRatesStore customRatesStore = CustomRatesStore();

/// Se reasigna en los tests para usar una fuente de tasas falsa.
RatesController ratesController = RatesController(
  source: ApiRateSource(),
  settings: appSettings,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _applyOrientationPolicy();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('es_VE', null);
  await appSettings.load();
  await customRatesStore.load();
  runApp(const LukasSyncApp());
  ratesController.start();
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
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF16A34A),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF16A34A),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: appSettings.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
