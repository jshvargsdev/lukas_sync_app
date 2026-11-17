# Lukas Sync

Conversor de monedas para Venezuela (Flutter, solo Android en la práctica). La
usan la familia y amigos del autor; se distribuye como APK, no en tiendas.
Ver `README.md` para funciones y estructura.

## Comandos

Flutter no está en el PATH: usar `export PATH=~/fvm/default/bin:$PATH`.

| Para | Comando |
|---|---|
| Dependencias | `flutter pub get` |
| Verificación (obligatoria antes de commit) | `flutter analyze && flutter test` |
| Correr en el teléfono | `flutter run --dart-define-from-file=config/prod.json` |
| APK para distribuir | `scripts/build_release.sh` (nunca `flutter build` a secas: saldría sin URL de la API) |
| Publicar versión | Ver `docs/publicar.md`, usando `gh-personal` en vez de `gh`. Crear el release es publicar: mostrar las notas y pedir OK antes. |

- `adb` está en `~/Android/Sdk/platform-tools/adb`.
- El JDK es el de Android Studio (Java 25): Gradle debe ser 9.1+.
- Teléfono de pruebas: Xiaomi (MIUI, Android 11). Requiere "Instalar vía USB" en
  Opciones de desarrollador y **aceptar el aviso en pantalla**: avisar al usuario
  antes de cada `adb install`.

## Reglas del proyecto

- **API**: `tasas-api` (repo aparte). El contrato está en `docs/api-v1.md`; si
  cambia, se actualiza ahí primero. Sin token: nunca meter secretos en el APK.
- **Nada sensible en el repo (es público)**: ni llaves, ni claves, ni URLs de
  servicios, ni detalles de infraestructura. La URL de la API vive en
  `config/prod.json` (ignorado por git); en el repo solo `config/example.json`.
- **Datos guardados de los usuarios**: no cambiar las claves de
  `SharedPreferences` (`@lukas_multi_rates`, `@lukas_theme_mode`,
  `@lukas_rates_cache`, …) ni su formato sin una lectura compatible con el
  anterior: la gente actualiza instalando encima.
- **Actualizaciones**: la app lee `releases/latest` de este repo y descarga el
  asset `app-<abi>-release.apk`. No cambiar esos nombres ni el formato del tag
  (`vX.Y.Z`) sin actualizar `lib/domain/app_release.dart`. El repo es público.
  Las notas del release van en texto plano (la app no interpreta Markdown).
- **Firma**: el release se firma con la llave de `android/key.properties`
  (el keystore está fuera del repo; su ruta está en ese archivo). Nunca commitear ni
  regenerar la llave: con otra llave las actualizaciones no se instalan encima.
- **Dinero y tasas**: las tasas se guardan y calculan sin redondear; solo se
  redondea al mostrar (`formatVes` para montos, `formatRate` para tasas). Usar
  esas funciones de `lib/domain/converter.dart`.
- **Colores**: siempre desde `context.palette` (`lib/theme/app_theme.dart`), nunca
  `Color(0x…)` sueltos en widgets.
- **Widget de Android** (`RemoteViews`): solo `FrameLayout`, `LinearLayout`,
  `TextView`, `ImageView`… Un `View` genérico rompe el widget en Android 11.
- **Textos** en español de Venezuela, mensajes de error específicos para el
  usuario.
- `dart format lib` reformatea `lib/models/custom_rate.dart` y
  `lib/services/custom_rates_store.dart`; no commitear ese cambio si no se tocó
  el archivo.

## Pruebas en el teléfono con datos falsos

Para capturas sin depender de la API se usa un punto de entrada temporal, por
ejemplo `lib/main_preview.dart`, que reasigna `ratesController` y
`rateHistorySource` con fuentes falsas, y se agrega a `.git/info/exclude`.
Se compila con `flutter build apk --debug -t lib/main_preview.dart` y se borra
al terminar.
