# Auditra — SPEC v1

(Working name during dev; app formerly referred to as "TradeAudit" in early discussion, renamed to avoid clashing with the real cryptobruj.com/TradeAudit product it was inspired by.)

## Resumen

App de escritorio standalone que replica el panel de analítica de trades de
TradeAudit, pero sobre wallets de Hyperliquid en vez de exchanges
centralizados. Sin registro, sin API keys, sin conexión con Arbiter — solo
lectura de datos públicos de una wallet.

Pensada como demo/prueba de concepto: si el equipo de Arbiter decide
integrarla en la app, se reutiliza la capa de cálculo y se cambia solo el
origen del dato.

## Decisiones de arquitectura (ya tomadas)

- **Plataforma**: Flutter Desktop (macOS / Windows / Linux) — reutiliza el
  mismo stack que Arbiter, permite reusar el chart engine propio
  (`CustomPainter`) si el código es accesible.
- **Fuente de datos**: API pública de Hyperliquid, consultada por wallet
  address. No hace falta API key de ningún exchange.
- **Autenticación**: ninguna. No es una acción que requiera permiso (no
  firma nada, no mueve fondos) — es lectura de datos que ya son públicos en
  la blockchain/DEX.
- **Alcance de wallet (v1)**: una sola dirección, introducida a mano por el
  usuario en el primer arranque. Guardada localmente (config del propio
  equipo, no en servidor).
- **Multi-exchange**: no. Solo Hyperliquid, a diferencia de TradeAudit
  (Bitget/Bitunix/BingX).
- **Futuro**: si Arbiter decide integrarlo directamente, ellos deciden la
  mejor forma de conectarlo (usar la wallet activa de la app sin pedirla a
  mano). No es una decisión de esta v1.

## Flujo de usuario (v1)

1. Primer arranque → pantalla pide pegar la dirección de wallet
2. Se guarda localmente
3. Botón "Sincronizar" → llama a la API de Hyperliquid, trae el historial
   de fills de esa dirección
4. Se calculan las métricas sobre esos fills
5. Se muestra el dashboard

## Roadmap por fases

- [x] **Fase 1 — Métricas base**
  PnL total, win rate, ganancia/pérdida media, expectativa matemática,
  ratio riesgo/beneficio, mayor ganancia/pérdida, PnL acumulado (gráfico)

- [x] **Fase 2 — Patrones temporales y direccionales**
  PnL y nº de trades por día, win rate por hora, win rate por día de la
  semana, longs vs shorts (conteo, win rate, PnL de cada dirección)

- [x] **Fase 3 — Análisis de comportamiento**
  Perfil de trader (scalper/day trader/swing según duración media),
  rachas de victorias/derrotas con PnL neto, ranking de pares más
  operados vs más rentables

- [x] **Fase 4 — Comisiones y vistas de apoyo**
  Comisiones totales/acumuladas, ratio ganancia-por-dólar-de-comisión,
  calendario visual, resumen mensual, listado de trades con filtros

## Fuera de alcance (v1)

- Multi-wallet / búsqueda de cualquier wallet (queda restringido a la
  propia, ver arriba)
- Conexión directa con Arbiter (QR, deep link, etc.) — descartado por
  ahora
- Cualquier acción de trading (cerrar posición, etc.) — es solo lectura
- Multi-exchange fuera de Hyperliquid

## Convenciones de código

- Todo el código en inglés (nombres de variables, funciones, clases,
  commits).
- Sin comentarios/anotaciones innecesarias — código limpio y
  autoexplicativo.
- Sin redundancias, estructura clara.

## Idiomas (i18n)

- La app soporta múltiples idiomas desde v1: inglés, español, francés y
  otros idiomas comunes (a definir lista final).
- Objetivo: no limitar el alcance a un mercado — cualquier usuario de
  Hyperliquid puede usar la app (no depende de ser usuario de Arbiter),
  así que el idioma no debería ser una barrera.

## API de Hyperliquid (confirmado)

- **Endpoint**: `POST https://api.hyperliquid.xyz/info`
- **Body**: `{"type": "userFills", "user": "<address>"}` — sin autenticación,
  solo la dirección pública
- **Campos por fill**: `coin`, `px`, `sz`, `side`, `dir` (texto legible,
  ej. "Open Long"), `time` (epoch ms), `closedPnl` (ya calculado por
  Hyperliquid — no hace falta reconstruirlo), `fee`, `feeToken`, `tid`
- **Paginación**: máx. 2.000 fills por respuesta. Para traer más,
  `userFillsByTime` con `startTime`/`endTime`
- **Límite conocido**: solo se pueden consultar los últimos 10.000 fills
  en total vía API pública — histórico más antiguo no es accesible. Es una
  limitación equivalente a la ventana de 90 días de TradeAudit, documentarla
  como tal en la UI si se alcanza el límite.
- **Rate limits**: existen, consultables vía `type: "userRateLimit"`. No
  debería ser un problema para sync manual de un solo usuario.

### Mitigación del límite de 10.000 fills

- Cada sync guarda localmente los fills nuevos desde la última sync (no
  solo se muestran, se persisten). Deduplicación por `tid` (identificador
  único de cada fill) — si el `tid` ya existe localmente, se ignora. Esto
  evita contar el mismo fill dos veces aunque la API devuelva de nuevo
  fills ya sincronizados en syncs anteriores.
- Solo el histórico previo a la primera sincronización queda limitado por
  la API de Hyperliquid (afecta sobre todo a usuarios muy activos). Todo
  lo que ocurra desde que el usuario empieza a usar la app queda
  acumulado sin depender del límite externo.
- Opción futura (fuera de v1): indexadores de terceros (GoldRush, Allium)
  ofrecen histórico completo sin el límite de 10.000, pero requieren API
  key de pago — no se contempla para v1.

## Pendiente de definir

- Detalles de implementación de la cache local (formato de almacenamiento,
  frecuencia de sync)
- Paleta/tipografía: heredar la de Arbiter o definir una propia
- Repo y estructura de carpetas
- Lista final de idiomas soportados más allá de inglés/español/francés

## Notas para handoff

- Sin dependencias de seguridad nuevas (no custodia, no firma) — cualquiera
  que retome esto no necesita contexto de agent wallets ni de Reown/
  WalletConnect, ese trabajo es independiente y vive en el hilo del web
  port de Arbiter.
- Si Arbiter decide integrarlo, la capa de cálculo (fases 1-4) se reutiliza
  tal cual; solo cambia de dónde vienen los fills.
