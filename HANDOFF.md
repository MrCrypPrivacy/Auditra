# Auditra — HANDOFF

Este documento es el punto de entrada para retomar el proyecto en otra
conversación. Léelo primero; `SPEC.md` (en la raíz del proyecto) tiene el
histórico de decisiones de diseño originales, pero este fichero refleja el
**estado real actual**, que ya se ha desviado bastante del SPEC v1 inicial
(se añadió multi-wallet, sync en tiempo real, reglas, notas... nada de eso
estaba en el alcance original).

## Qué es esto

Auditra es una app de escritorio Flutter (Linux/Windows/macOS) que audita
el trading de una o varias wallets de Hyperliquid: métricas de PnL, win
rate, drawdown, patrones horarios, comportamiento, comisiones, reglas
propias y notas por operación. Nace como réplica mejorada de TradeAudit
(cryptobruj.com), pero sobre Hyperliquid en vez de exchanges centralizados,
sin API keys ni registro — solo lectura pública por dirección de wallet.

Contexto de negocio: lo construye el equipo de **Arbiter** (wallet de
autocustodia para Arbitrum con perpetuos de Hyperliquid) como demo/prueba
de concepto. Si el equipo de Arbiter decide integrarlo en la app principal
más adelante, la capa de cálculo se reutiliza tal cual — solo cambia de
dónde vienen los fills.

## Entorno de desarrollo

- Se desarrolla y compila en local (Fedora, KDE Plasma, GPU NVIDIA) con
  `flutter run -d linux` / `flutter build linux --release`.
- Quien continúe esto **no tiene acceso a ejecutar Flutter** si es Claude
  en un chat sin herramienta de computer use con Flutter instalado — todo
  el código de este proyecto se ha escrito "a ciegas", sin poder compilar,
  y se ha depurado en rondas sucesivas a partir de los logs de error que
  el usuario pega del `flutter run` real. Ese es el flujo de trabajo
  esperado: escribir/editar código → el usuario compila → pega el log si
  falla → se diagnostica y arregla.
- El proyecto usa `flutter create .` para generar las carpetas nativas
  (`linux/`, `windows/`, `macos/`), que **no están en el zip que se
  entrega** — las genera el usuario localmente. Cualquier cambio a
  ficheros nativos (icono, título de ventana) requiere pedirle al usuario
  el contenido actual del fichero nativo antes de editarlo a ciegas.

## Cómo compilar

```bash
flutter clean
flutter pub get
flutter run -d linux
```

`flutter pub get` también genera `lib/l10n/generated/app_localizations.dart`
a partir de los `.arb` en `lib/core/l10n/` (vía `l10n.yaml` +
`generate: true` en `pubspec.yaml`). Ese fichero generado nunca existe en
el zip entregado — es normal que las comprobaciones de imports lo marquen
como "no encontrado", no es un error real.

Tests:
```bash
flutter test
```

## Git

El proyecto **no tiene repositorio git inicializado** hasta donde se sabe.
Si quien continúa quiere tenerlo, los pasos son:
```bash
cd auditra
git init
git add .
git commit -m "Initial commit: Auditra vX"
```
No hay convención de mensajes de commit establecida más allá de "código en
inglés, sin comentarios innecesarios" (ver `SPEC.md` → Convenciones de
código).

## Stack técnico

- Flutter Desktop, sin librerías de gráficos de terceros — todos los
  charts son `CustomPainter` hechos a mano (decisión temprana, para poder
  reutilizar el motor de charts de Arbiter si algún día hay acceso al
  código real).
- `window_manager` — barra de título propia (nativa oculta), tamaño de
  ventana.
- `web_socket_channel` — sync en tiempo real contra el WS de Hyperliquid.
- `file_selector` — diálogos nativos de exportar/importar.
- `path_provider` — todos los datos persistidos son ficheros JSON en el
  directorio de datos de la app (`getApplicationSupportDirectory()`), uno
  por wallet + tipo de dato (`fills_<address>.json`, `notes_<address>.json`,
  `rules_<address>.json`, `wallets.json`, `app_prefs.json`).
- `intl` — formateo de fechas/meses localizado. **Cuidado**: `intl`
  exporta su propia clase `TextDirection` que choca con la de Flutter; si
  un fichero nuevo importa `intl` y usa `TextPainter`/`TextDirection.ltr`,
  hay que hacer `import 'package:intl/intl.dart' hide TextDirection;`.
- 10 idiomas: en, es, fr, de, it, pt, ru, ar, zh, ja — árbol de claves en
  `lib/core/l10n/app_*.arb`. Cualquier texto nuevo en la UI debe pasar por
  ahí, no hardcodearse (ya se han colado un par de veces textos sueltos en
  inglés — "Theme"/"Language" en Settings es un ejemplo pendiente de
  arreglar, ver más abajo).

## Estructura del código

```
lib/
├── app.dart                    # MaterialApp, theme/locale controllers, barra de título
├── main.dart                   # bootstrap, window_manager, exit(0) al cerrar
├── core/
│   ├── network/                # HyperliquidClient (REST), HyperliquidWsClient (WS),
│   │                            ExportImportService
│   ├── storage/                # *LocalStore para cada tipo de dato (wallets, fills,
│   │                            notes, rules, prefs), ResetService
│   ├── rules/                  # TradeRule, RuleEvaluator
│   ├── filters/                # PeriodFilter (Todo/Hoy/Semana/Mes/Año)
│   ├── format/                 # formatAxisNumber, formatDuration
│   ├── theme/                  # AppTheme (brand + arbiter), ThemeController
│   └── l10n/                   # LocaleController, AppLocales, *.arb
├── features/
│   ├── onboarding/              # WalletInputScreen, LaunchDecider
│   ├── settings/                # SettingsScreen (pendiente de reorganizar, ver abajo)
│   └── dashboard/
│       ├── domain/              # Fill (modelo de dato de Hyperliquid)
│       ├── application/         # *Metrics — toda la lógica de cálculo, con cacheo
│       │                         por fingerprint (length+first/last tid)
│       └── presentation/
│           ├── dashboard_screen.dart   # shell: sidebar + sync + wallets + reglas
│           ├── overview_screen.dart    # pestaña Resumen
│           ├── trades_screen.dart      # pestaña Trades + notas
│           ├── behavior_screen.dart    # pestaña Comportamiento
│           ├── rules_screen.dart       # pestaña Reglas
│           ├── fees_screen.dart        # pestaña Comisiones
│           └── widgets/                # los CustomPainter de cada gráfico
└── shared/widgets/              # sidebar, title bar, botones, selectores reutilizables
```

## Qué está hecho

Las 4 fases del SPEC v1 original, completas:
- Fase 1 — PnL total, win rate, expectativa, riesgo/beneficio, drawdown
  máximo (absoluto y %), PnL acumulado
- Fase 2 — Actividad diaria (longs/shorts + win rate), PnL por día, win
  rate por hora del día, win rate por día de la semana, direccionalidad
  (longs vs shorts: conteo/win rate/PnL)
- Fase 3 — Perfil de trader (scalper/day trader/swing por duración
  reconstruida vía `startPosition`), rachas ganadoras/perdedoras, ranking
  de pares (más operados/más y menos rentables), correlación tamaño de
  posición vs win rate
- Fase 4 — Comisiones totales/diarias/acumuladas, ratio PnL por $ de
  comisión, calendario heatmap por mes, resumen mensual

Extras fuera del SPEC original, añadidos por petición del usuario:
- **Multi-wallet con nombre** (ej. "Arbiter", "Hyperliquid") — cada una
  con su propio histórico/notas/reglas, seleccionable desde Settings
- **Sync en tiempo real** vía WebSocket (`userFills`), con reconexión
  automática con backoff exponencial, + botón de sync manual con manejo
  de errores visible
- **Reglas de trading** definidas por el usuario (no operar tal día de la
  semana / máximo de trades por día / no operar en un rango de horas),
  con detección de incumplimientos contra el histórico real y alerta
  proactiva en Overview si hay incumplimientos en los últimos 7 días
- **Notas por operación** en la pestaña Trades, con buscador por par
- **Exportar/Importar** en JSON y CSV
- **Selector Periodo + Origen** (una wallet concreta o todas fusionadas)
- **Tema doble** (marca propia "Auditra" en verde lima `#CCFF33` + un
  placeholder "Arbiter" a la espera de la paleta real) e idioma,
  persistidos entre sesiones
- **Botón de reset total de datos** en Settings, con confirmación
- **Tests unitarios** de `pnl_metrics` y `behavior_metrics`, incluyendo un
  test de regresión específico para el bug de coma flotante (ver abajo)
- **Gráficos interactivos**: todos los `CustomPainter` tienen eje con
  valores, líneas de referencia y tooltip al pasar el cursor (`MouseRegion`
  + hover)

## Bugs conocidos y su estado

- **Crash al cerrar la app** (`libnvidia-eglcore`/`libEGL_nvidia`, driver
  propietario de NVIDIA en su propia limpieza al salir): se añadió
  `exit(0)` forzado en `AppWindowListener.onWindowClose` para saltarse los
  `atexit` handlers del driver. Pendiente de confirmación de que
  desapareció del todo.
- **"Perfil de trader" en 0%/0s**: diagnosticado como comparación exacta
  (`== 0`) con residuo de coma flotante en `startPosition`. Arreglado con
  un epsilon (`1e-6`) en `behavior_metrics.dart`, con test de regresión en
  `test/behavior_metrics_test.dart`. **El usuario reportó que seguía
  viéndolo igual tras el fix y decidimos aparcarlo sin más investigación**
  — queda pendiente confirmar si el fix realmente lo resolvió o si hay
  una segunda causa sin identificar.
- **`RenderCustomPaint`/`Stack` con tamaño infinito**: cualquier chart
  (`PnlChart`, `DailyPnlChart`, `ActivityChart`, `WinRateBarChart`) que se
  coloque como hijo directo de un `Column` **sin** envolverlo en
  `Expanded` recibe altura no acotada y revienta en cascada (decenas de
  excepciones secundarias: "Cannot hit test", "RenderBox was not laid
  out", etc. — todas síntomas del mismo fallo raíz, no bugs
  independientes). Ya se ha dado esta clase de bug dos veces (Comisiones
  diarias, y un `Spacer()` metido dentro de un `Wrap` en vez de un
  `Row`/`Flex`). **Si aparece una avalancha de excepciones parecida en el
  futuro, buscar primero un `Expanded`/`Spacer` mal anidado antes de
  investigar nada más** — es el patrón de bug más repetido en este
  proyecto.
- **`intl` vs `TextDirection`**: ver sección "Stack técnico" arriba.

## Pendiente — en curso, con plan ya acordado

### Rediseño visual de Overview (por fases, en progreso)
El usuario mandó capturas de referencia de cómo debería verse el
dashboard (tarjetas del mismo tamaño, cuadrícula centrada, navegación mes
a mes, donuts en vez de barras para Dirección/Perfil de trader, rachas en
3 tarjetas separadas con "Recuperación post pérdida", pares en tarjetas
de ancho completo, ratio de comisiones). Plan acordado:
1. ~~Bugs de datos~~ ✅
2. ~~Infraestructura de gráficos (ejes, tooltips)~~ ✅
3. Cuadrícula de tamaños uniformes — **siguiente paso**
4. Navegación mes a mes en los paneles que la necesiten
5. Donuts, tarjeta de Recuperación, Pares en tarjetas separadas, ratio de
   comisiones por día

### Reorganización de Settings
Se propuso (pendiente de confirmar/ejecutar) reestructurar la pantalla en
4 secciones con cabecera clara: Wallets / Apariencia (fusionar Tema +
Idioma) / Datos (un botón Exportar con desplegable JSON/CSV en vez de 3
botones sueltos) / Zona de peligro (reset). De paso, traducir "Theme" y
"Language" — son los únicos textos de toda la app que quedaron
hardcodeados en inglés sin pasar por el sistema de `l10n`.

### Otras mejoras mencionadas y descartadas (no reabrir salvo que el
usuario lo pida explícitamente)
Comparativa entre wallets lado a lado, marcar rachas como "aprendizaje"
vinculado a notas, objetivos/metas mensuales — el usuario dijo
explícitamente "no por ahora" a estas tres.

## Cómo trabajar con este usuario (aprendido durante el proyecto)

- Prefiere rondas grandes ("puedes hacer todo esto") a base de fases
  bien delimitadas, pero valora que se le avise cuando algo es
  desproporcionadamente grande antes de lanzarse.
- Pide explícitamente "antes de hacer ningún cambio, respóndeme primero"
  con frecuencia — respetarlo a rajatabla, no adelantar código en esas
  respuestas.
- Cuando pega un log de error, suele ser un wall of text enorme con
  decenas de excepciones en cascada — el trabajo real es encontrar la UNA
  causa raíz entre el ruido, no perseguir cada línea.
- Aprecia que se le diga honestamente cuándo algo no se ha podido
  verificar (no hay Flutter en este entorno) en vez de aparentar
  seguridad.
- Todas las decisiones de idioma/estilo de código quedan en `SPEC.md`
  → Convenciones de código: inglés, sin comentarios, limpio.
