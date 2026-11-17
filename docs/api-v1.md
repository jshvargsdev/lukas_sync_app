# API de tasas v1

Contrato que espera Lukas Sync 2.0 de la API nueva que reemplaza a
`tasas-sync-api`. Estado: **cerrado** (2026-11-17), implementado y en producción.

- URL base: `https://tasas-api-liart.vercel.app`
- Código: repo `jshvargsdev/tasas-api` (su README explica el funcionamiento interno)
- Compilar la app: `--dart-define=RATES_API_BASE_URL=https://tasas-api-liart.vercel.app`

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Hosting | Vercel, plan gratuito. Región `gru1` (São Paulo): Binance P2P bloquea IPs de EE. UU. |
| Base de datos | Postgres en Neon (Vercel Marketplace, plan gratuito, `sa-east-1`) |
| BCV | Leído directo de bcv.org.ve, sin APIs de terceros. Se guarda en BD por **fecha valor**, sin redondear |
| USDT | Binance P2P, lado compra, Pago Móvil, **solo comerciantes verificados**. **Promedio de los primeros 10 anuncios**; si vienen menos de 10, no hay tasa (`usdt: null`). No se guarda; se calcula al vuelo con caché de CDN de 5 min |
| Correcciones del BCV | Si el BCV publica otros valores para una fecha valor ya guardada, se actualiza y lo anterior queda registrado en la BD |
| Tasa vigente | En fines de semana y feriados aplica la última fecha valor anterior |
| Historial | Solo BCV. Sin importar histórico previo: empieza cuando arranque la API |
| Autenticación | Ninguna en los endpoints de lectura (datos públicos). Así no hay token dentro del APK |
| Compatibilidad | `tasas-sync-api` sigue activa hasta que toda la familia tenga la app 2.0; luego se apaga |

## Recolección del BCV

- Cron diario de Vercel (el plan gratuito permite uno al día) a las 22:00 UTC
  (18:00 en Venezuela; Vercel lo corre dentro de esa hora). Guarda
  `(fecha_valor, usd, eur, fetched_at)`.
- Respaldo: si al pedir `/v1/rates/latest` la última fecha valor guardada es
  anterior a hoy (hora de Venezuela), el endpoint intenta leer el BCV en ese
  momento y la guarda. Como mucho una vez cada 30 min y con 5 s de timeout.
  Los fines de semana no se dispara: el viernes el BCV ya publica la del lunes.
- Si el BCV no responde o el HTML cambió, **no se sobrescribe nada**: se
  sirve el último valor bueno.

## Endpoints

Todas las cifras son bolívares por unidad, como número sin redondear.
Fechas: `AAAA-MM-DD` en hora de Venezuela; instantes en ISO 8601 UTC.

### `GET /v1/rates/latest`

```json
{
  "bcv": {
    "usd": 236.4583,
    "eur": 274.1032,
    "valueDate": "2026-11-18",
    "fetchedAt": "2026-11-17T21:05:00Z"
  },
  "usdt": {
    "value": 312.5,
    "sampleSize": 10,
    "fetchedAt": "2026-11-17T14:00:00Z"
  }
}
```

- Si Binance falla, `usdt` es `null` y el BCV se sigue devolviendo.
- `bcv.valueDate` es la fecha valor más reciente guardada: puede ser de mañana
  si el BCV ya publicó.
- `503` si todavía no hay ninguna tasa del BCV (solo pasaría con la BD vacía y
  el BCV caído).
- `Cache-Control: public, s-maxage=300, stale-while-revalidate=60`. Con poco
  tráfico, un `stale-while-revalidate` largo haría que casi todos recibieran el
  USDT de la petición anterior; así tiene como mucho ~6 min.

### `GET /v1/rates/bcv/history?before=2026-11-16&limit=30`

Publicaciones del BCV (una por fecha valor), de la más reciente a la más
antigua. Es lo que usa la pantalla Historial: un card por publicación,
cargando más al bajar.

- `before` (opcional): solo publicaciones con `valueDate < before`. Sin él,
  empieza por la más reciente (puede ser de mañana si el BCV ya publicó).
- `limit` (opcional, por defecto 30, máximo 100).

```json
{
  "items": [
    { "valueDate": "2026-11-13", "usd": 235.91, "eur": 273.4 },
    { "valueDate": "2026-11-12", "usd": 235.55, "eur": 273.02 }
  ],
  "nextBefore": "2026-11-12"
}
```

- `nextBefore`: valor de `before` para la página siguiente; `null` si no hay más.
- **Tasa vigente en una fecha** (regla confirmada): la de mayor `valueDate`
  que sea `<= fecha`. Cubre fines de semana y feriados, en los que no hay
  publicación. La app la obtiene con `before = fecha + 1 día` y toma el
  primer elemento, así que no hace falta un endpoint aparte.
- `400` si `before` o `limit` son inválidos.
- `Cache-Control: public, s-maxage=600, stale-while-revalidate=3600`.

### Errores

Cualquier respuesta que no sea 200 lleva el mensaje en español:

```json
{ "error": { "code": "INVALID_BEFORE", "message": "El parámetro \"before\" debe ser una fecha válida con formato AAAA-MM-DD." } }
```

| Código HTTP | `code` |
|---|---|
| 400 | `INVALID_BEFORE`, `INVALID_LIMIT` |
| 404 | `NOT_FOUND` |
| 500 | `INTERNAL` |
| 503 | `BCV_UNAVAILABLE` |

## Lo que hace la app con esto

- `RateSource` nuevo (`V1RateSource`) que lee `/v1/rates/latest`. Sin token;
  la URL base va por `--dart-define`.
- Pantalla **Historial**: un card por publicación con dólar y euro en
  columnas, carga al bajar y un calendario para saltar a una fecha.
- Se elimina `.env` como asset del APK.
