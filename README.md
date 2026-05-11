# Lukas Sync

Conversor de monedas para Venezuela construido en Flutter. Muestra y permite convertir entre el bolívar (VES), el dólar y euro a tasa BCV, el USDT de Binance P2P y tasas personalizadas definidas por el usuario.

## Características

- Tasas oficiales del BCV (USD y EUR) y de Binance P2P (USDT) consultadas desde una API propia.
- Tasas personalizadas: el usuario puede crear, editar, reordenar y eliminar sus propias tasas con nombre e ícono.
- Conversor con teclado numérico personalizado: al tocar una tarjeta se vuelve la moneda activa y el resto se recalcula al instante.
- Caché local de la última respuesta de la API para mostrar valores aún sin conexión.
- Refresco automático configurable (15, 30 o 60 minutos) más refresco manual con pull‑to‑refresh.
- Tema claro / oscuro / sistema, persistido entre sesiones.
- Localización en `es_VE` (formato de números y fechas venezolano).
- Orientación adaptativa: vertical en teléfonos, vertical y horizontal en tablets.

## Requisitos

- Flutter SDK con Dart `^3.11.5`.
- Una cuenta y endpoint de la API de tasas que devuelva el formato esperado (ver más abajo).

## Configuración

1. Instala dependencias:

   ```bash
   flutter pub get
   ```

2. Crea el archivo `.env` en la raíz copiando el ejemplo:

   ```bash
   cp .env.example .env
   ```

   Y edita los valores:

   ```env
   RATES_API_URL=https://tu-api.example.com/rates
   RATES_API_TOKEN=tu-token-aqui
   ```

   El archivo `.env` está declarado como asset en `pubspec.yaml`, así que debe existir antes de compilar.

3. (Opcional) Regenera íconos y splash si modificas `assets/icon.png`:

   ```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```

## Ejecución

```bash
flutter run                    # dispositivo conectado / emulador por defecto
flutter run -d android         # Android
flutter run -d ios             # iOS
```

## Build de producción

```bash
flutter build apk --release            # APK Android
flutter build appbundle --release      # AAB para Play Store
flutter build ios --release            # iOS (requiere macOS + Xcode)
```

## Formato esperado de la API

El endpoint configurado en `RATES_API_URL` debe responder a `GET` con el header `Authorization: Bearer <RATES_API_TOKEN>` y devolver JSON con la siguiente estructura:

```json
{
  "ok": true,
  "data": {
    "fetchedAt": "2026-05-11T12:00:00Z",
    "bcv": {
      "dollar": { "value": 36.50 },
      "euro":   { "value": 39.80 }
    },
    "binance": { "value": 37.10 }
  }
}
```

## Estructura del proyecto

```
lib/
├── main.dart                  # Inicialización, tema y configuración global
├── constants/                 # Constantes (íconos/emojis disponibles)
├── models/                    # Modelos (CustomRate)
├── services/                  # AppSettings, CustomRatesStore, RateService
├── screens/                   # HomeScreen, SettingsScreen, ReorderRatesScreen
└── widgets/                   # CurrencyCard, AddRateCard, AddRateModal, CustomKeypad
```

## Dependencias principales

- `http` — llamadas a la API de tasas.
- `shared_preferences` — persistencia de tema, intervalo de refresco, tasas personalizadas y caché.
- `flutter_dotenv` — carga de variables de entorno desde `.env`.
- `intl` — formato de números y fechas en `es_VE`.
- `url_launcher`, `package_info_plus` — enlaces externos y datos de versión en ajustes.
