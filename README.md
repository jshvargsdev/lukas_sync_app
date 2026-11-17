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

## Publicar una versión

La app busca versiones nuevas en los
[Releases](https://github.com/jshvargsdev/lukas_sync_app/releases) de este repo
(`releases/latest`), así que publicar es crear un release:

1. Sube `version` en `pubspec.yaml` (p. ej. `2.1.0+3` → `2.2.0+4`; el número
   después de `+` siempre debe subir).
2. `flutter analyze && flutter test`.
3. `scripts/build_release.sh`.
4. Crea el release con tag `v<versión>`, los tres APK con su nombre original
   (`app-<abi>-release.apk`) y las notas en español **en texto plano** (sin
   Markdown: la app las muestra tal cual, así que `**` o `*` se verían). Para
   listas usa `•`:

   ```bash
   gh release create v2.2.0 \
     build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
     build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
     build/app/outputs/flutter-apk/app-x86_64-release.apk \
     --title "Lukas Sync 2.2.0" --notes-file notas.txt
   ```

Las apps instaladas lo detectan en un máximo de 6 horas (o al tocar "Buscar" en
Ajustes > Actualizaciones). No publiques un release como "latest" si no
quieres que todos lo reciban: para pruebas usa `--prerelease`, que la API de
`releases/latest` ignora.

## Firma

El APK release se firma con la llave de release si existe `android/key.properties`
(ignorado por git). Si no existe, se firma con la llave de debug de la máquina.

1. Copia `android/key.properties.example` a `android/key.properties` y completa
   la ruta al keystore y sus claves.
2. El keystore **no va en el repo**. Guárdalo, junto con su clave, en un lugar
   seguro con respaldo: sin él no se pueden publicar actualizaciones que se
   instalen encima de la versión que ya tienen los usuarios.

Huella SHA-256 del certificado de release:
`41:0C:E2:A2:9F:46:33:DD:B0:9D:EF:9A:5C:E8:C3:3D:61:5E:DE:27:E4:4E:02:86:70:9A:F8:27:7B:10:45:05`

Para comprobar la firma de un APK:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

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
