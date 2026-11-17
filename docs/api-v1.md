# API de tasas v1 (propuesta)

Contrato que espera Lukas Sync 2.0 de la API nueva que reemplaza a
`tasas-sync-api`. Estado: **propuesta**, se cierra en la sesión de la API.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Hosting | Vercel, plan gratuito |
| Base de datos | Postgres en Neon (Vercel Marketplace, plan gratuito) |
| BCV | Leído directo de bcv.org.ve, sin APIs de terceros. Se guarda en BD por **fecha valor**, sin redondear |
| USDT | Binance P2P, lado compra, Pago Móvil. **Promedio de los primeros N anuncios** (N a definir, 5–10). No se guarda; se calcula al vuelo con caché de CDN (~10 min) |
| Tasa vigente | En fines de semana y feriados aplica la última fecha valor anterior |
| Historial | Solo BCV. Sin importar histórico previo: empieza cuando arranque la API |
| Autenticación | Ninguna en los endpoints de lectura (datos públicos). Así no hay token dentro del APK |
| Compatibilidad | `tasas-sync-api` sigue activa hasta que toda la familia tenga la app 2.0; luego se apaga |

## Recolección del BCV

- Cron diario de Vercel (el plan gratuito permite uno al día) después de que el
  BCV publica, que suele ser en la tarde. Guarda `(fecha_valor, usd, eur, fetched_at)`.
- Respaldo: si al pedir `/v1/rates/latest` la última tasa guardada tiene más
  de un día, el endpoint intenta leer el BCV en ese momento y la guarda.
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
- `Cache-Control: public, s-maxage=600, stale-while-revalidate=3600`.

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

## Lo que hace la app con esto

- `RateSource` nuevo (`V1RateSource`) que lee `/v1/rates/latest`. Sin token;
  la URL base va por `--dart-define`.
- Pantalla **Historial**: un card por publicación con dólar y euro en
  columnas, carga al bajar y un calendario para saltar a una fecha.
- Se elimina `.env` como asset del APK.
