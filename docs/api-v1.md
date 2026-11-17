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

### `GET /v1/rates/bcv?date=2026-11-15`

Tasa BCV **vigente** en esa fecha:

```json
{
  "date": "2026-11-15",
  "valueDate": "2026-11-13",
  "usd": 235.91,
  "eur": 273.4
}
```

- Regla (confirmada): la vigente es la de mayor `valueDate` que sea `<= date`.
  Cubre fines de semana y feriados, en los que no hay publicación.
- `404` si la fecha es anterior al primer registro guardado, con un mensaje
  en español.
- `400` si la fecha es inválida o futura.

## Lo que hace la app con esto

- `RateSource` nuevo (`V1RateSource`) que lee `/v1/rates/latest`. Sin token;
  la URL base va por `--dart-define`.
- Pantalla **Historial**: se elige una fecha y muestra el dólar y el euro BCV
  vigentes ese día, indicando la fecha valor si es distinta.
- Se elimina `.env` como asset del APK.
