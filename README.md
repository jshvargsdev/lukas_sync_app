# Lukas Sync

Conversor de monedas para Venezuela construido en Flutter. Convierte entre el
bolívar (VES), el dólar y el euro a tasa BCV, el USDT de Binance P2P y tasas
personalizadas definidas por el usuario.

Pensada para Android (es la plataforma que se prueba y distribuye). El código
de iOS existe pero no se ha probado, y el widget es solo para Android.

## Características

- **Tasas oficiales** del BCV (USD y EUR) y USDT de Binance P2P desde la API
  propia [`tasas-api`](https://github.com/jshvargsdev/tasas-api)
  (contrato en [`docs/api-v1.md`](docs/api-v1.md)). Sin token: los endpoints
  de lectura son públicos.
- **Conversor**: la moneda activa se muestra en grande y debajo sus
  equivalencias. Tocar una fila la vuelve activa; su botón copia el monto.
- **Teclado numérico** propio; el monto se escribe en centavos.
- **Tasas personalizadas** con nombre, ícono y valor de hasta 6 decimales (para
  monedas que valen menos de 1 Bs, como el peso colombiano). Mantener
  presionada una tasa permite copiarla o editarla.
- **Historial BCV**: un card por publicación con dólar y euro, carga al bajar
  y calendario para ir a una fecha. En fines de semana y feriados aplica la
  última fecha valor anterior.
- **Widget de pantalla de inicio** (Android, 4×1) con las tres tasas y su
  hora. Se actualiza cuando la app descarga tasas y cada hora en segundo plano.
- Refresco cada hora con la app abierta y al volver a ella; refresco manual
  con el botón o deslizando hacia abajo. Caché local para funcionar sin conexión.
- **Actualizaciones desde la app**: avisa cuando hay un release nuevo en
  GitHub, descarga el APK del teléfono y abre el instalador.
- Ajustes (engranaje del Home): tema claro / oscuro / sistema, versión
  instalada y búsqueda de actualizaciones.
- Formato venezolano de números y fechas (`es_VE`).

## Requisitos

- Flutter 3.44 (Dart `^3.11.5`).
- Para Android: Android SDK y JDK (el de Android Studio sirve).

## Ejecución

```bash
flutter pub get
```

La URL de la API no está en el repo. Crea `config/prod.json` (ignorado por
git) a partir del ejemplo y complétalo:

```bash
cp config/example.json config/prod.json
flutter run --dart-define-from-file=config/prod.json
```

Sin ese archivo la app compila, pero muestra "La app no tiene configurado el
servicio de tasas".

## Verificación

```bash
flutter analyze
flutter test
```

## Build de producción

```bash
scripts/build_release.sh
```

Verifica que existan `config/prod.json` y `android/key.properties` (sin ellos
la app no tendría tasas o no se podría actualizar encima) y corre
`flutter build apk --release --split-per-abi`. Genera un APK por arquitectura
en `build/app/outputs/flutter-apk/`; para casi todos los teléfonos actuales
sirve `app-arm64-v8a-release.apk`. No uses `flutter build` a secas: el APK
saldría sin la URL de la API.

## Publicar y firmar

Cómo publicar una versión (para que las apps instaladas la reciban) y cómo
funciona la firma de release: ver [`docs/publicar.md`](docs/publicar.md).

## Estructura del proyecto

```
lib/
├── main.dart          # Arranque, tema, localización y dependencias globales
├── constants/         # Íconos/emojis para tasas personalizadas
├── domain/            # Lógica pura: conversión, formatos, versiones/releases
├── models/            # Rates, CustomRate, BcvPublication
├── services/          # API v1, tasas, almacenamiento, widget, actualizador
├── screens/           # Home e Historial
├── theme/             # Paleta clara/oscura y tema (AppPalette)
└── widgets/           # Teclado, filas, formulario de tasa, Ajustes, actualización
android/app/src/main/
├── kotlin/.../MainActivity.kt          # Canal nativo del actualizador (instalar APK)
├── kotlin/.../RatesWidgetProvider.kt   # Widget de pantalla de inicio
└── res/layout/rates_widget.xml         # Diseño del widget
config/example.json    # Plantilla de config/prod.json (URL de la API, fuera de git)
scripts/build_release.sh  # Build de release con las verificaciones previas
docs/api-v1.md         # Contrato con tasas-api
```

## Dependencias principales

- `http` — llamadas a la API de tasas.
- `shared_preferences` — tema, tasas personalizadas y caché de tasas.
- `intl` + `flutter_localizations` — formatos `es_VE` y textos del sistema en español.
- `home_widget` — datos y actualización del widget de Android.
- `workmanager` — descarga horaria en segundo plano para el widget.
- `url_launcher`, `package_info_plus` — enlace a GitHub en Ajustes y versión instalada.
