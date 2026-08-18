# C15 · La sesión en la isla dinámica

**Tipo:** Feature · **Estado:** ✅ Cerrado

Con una sesión corriendo y la app en segundo plano, el tiempo se ve en la isla dinámica, con un
botón para detenerla que abre la app directo al modal de página.

## Las dos decisiones que se tomaron antes de escribir código

### 1. El piso de iOS de la app no se toca — solo el del target nuevo

Live Activities existe desde iOS 16.1, pero la forma de la API que se terminó usando
(`ActivityContent`, la que reemplazó a la original dos meses después) pide 16.2 — se descubrió
al compilar, cuando el compilador rechazó `Activity.request(attributes:content:pushType:)` por
pedir 16.2. Se preguntó si subir el piso de la app a 16.1 para esto; Sergio dijo que no, que se
buscara otra forma. La forma encontrada: el piso de la app (y el de los dos targets de test) se
queda en 16.0, tal como estaba. Solo `tomotecaWidget` —el target nuevo, que solo existe para
alojar la Live Activity— sube a 16.2, porque una extensión de Live Activity nunca se carga en un
sistema más viejo que el que declara. Todo lo que toca `ActivityKit` del lado de la app vive
detrás de `if #available(iOS 16.2, *)`, sostenido a través de un protocolo
(`ReadingSessionLiveActivityUpdating`) en vez de con el piso mínimo del target subido.

No hace falta llegar a iOS 17: los botones interactivos "de verdad" dentro de una Live Activity
(`LiveActivityIntent`) sí piden 17, pero lo que se pidió —que el botón **abra la app** en el
modal de página, no que la cierre sin abrirla— es exactamente lo que 16.2 ya sabe hacer con un
enlace corriente.

Fuentes: [Live Activities requieren iOS 16.1](https://infinum.com/blog/live-activities-in-ios-apps/),
[los botones interactivos son de iOS 17](https://medium.com/@bancarel.paul/leveraging-live-activities-on-ios-with-activitykit-6821918215f3).

### 2. El target nuevo se creó con una herramienta, no a mano ni desde Xcode

Se preguntó si crear el target de la extensión requería abrir Xcode. Sergio prefirió que se
intentara igual, editando el proyecto. En vez de escribir `project.pbxproj` a mano —que es
exactamente lo que salió mal en el C14 para una sola clave—, se instaló la gema `xcodeproj` (la
misma que usa CocoaPods para esto) y se usó su API para generar el target, sus build phases, la
dependencia con la app y el paso de embeberlo. Genera UUIDs y estructura válidos por construcción,
en vez de adivinarlos.

## Alcance

**Entra**

- Con una sesión corriendo, isla dinámica: compacta (icono + tiempo) y expandida al mantener
  presionada (título del libro, tiempo, botón de detener)
- Pantalla de bloqueo: lo mismo, en el widget de actividad en vivo
- El tiempo se ve corriendo de verdad, sin que la app tenga que estar despierta actualizándolo
- Al pausar la sesión desde la propia app, la isla deja de correr y muestra el tiempo congelado
- El botón de detener abre la app y deja ver el modal de página, igual que "Terminar" en la
  pantalla de sesión
- Sesiones con tiempo fijo y libres, las dos

**No entra**

- Botones que actúen sin abrir la app (pausar, o detener sin abrir) — eso sí es iOS 17
- Notificación al llegar a cero: ya existe (C02), no cambia
- Android, iPad, o cualquier dispositivo sin isla dinámica — ahí la Live Activity sigue
  existiendo (en la pantalla de bloqueo), solo que sin la isla

## Cómo funciona

```
Compacta                              Expandida (mantener presionada)
┌──────────────────────┐              ┌────────────────────────────────┐
│ 📖          09:42    │              │ 📖   Cien años de soledad  09:42│
└──────────────────────┘              │            [ Detener ]          │
                                       └────────────────────────────────┘
```

Al arrancar una sesión, además de lo que ya pasa hoy (guardar el estado, programar el aviso), se
pide una Live Activity con el libro y el plan. Mientras corre, el número de la isla se mueve
solo — no es la app empujando actualizaciones cada segundo, es una cuenta que el sistema anima
él mismo a partir de una fecha de fin, igual que el temporizador nativo del Reloj.

Pausar y reanudar sí piden una actualización explícita, porque ahí el número dejó de correr por
una fecha y pasó a estar congelado en un valor fijo.

Tocar "Detener" abre la app con un enlace propio (`tomoteca://sesion/terminar`). La app lo
recibe, hace exactamente lo que hace hoy el botón "Terminar" de la pantalla de sesión, y aparece
el modal de página — el mismo camino, la misma pantalla, dos puertas de entrada.

Terminada la sesión —desde la isla o desde dentro de la app— la Live Activity se cierra sola.

## Decisiones

- **El botón abre la app, no actúa por su cuenta.** Es lo único posible en iOS 16.2 sin llegar a
  17, y además es lo que se pidió: que se abra el modal de página, no que la sesión se cierre en
  silencio sin que nadie escriba dónde se quedó.
- **El tiempo se anima solo, vía `Text(timerInterval:)` con la fecha de fin ya calculada** — no
  un `Timer` de la app empujando actualizaciones cada segundo. Es lo que Apple recomienda
  explícitamente para esto, y evita despertar la app en segundo plano solo para mover un número.
- **Una sesión libre no puede usar `Text(timerInterval:)`, porque no cuenta hacia una fecha de
  fin — no tiene una.** Para esas la isla muestra el último valor que la app empujó, congelado
  hasta que la app vuelva a primer plano — la misma pausa automática del C13 evita que eso cuente
  de más si se olvida corriendo.
- **`ActiveSessionController` es quien pide, actualiza y cierra la actividad**, no el ViewModel
  de la pantalla de sesión: ya es el dueño de la sesión activa durante toda la vida de la app, y
  observa `sessionViewModel.$phase` para saber cuándo pausó o reanudó sin acoplar el ViewModel a
  ActivityKit en absoluto.
- **`ReadingSessionLiveActivityController` es un tipo aparte, marcado `@available(iOS 16.2, *)`
  entero.** `ActiveSessionController` lo sostiene a través del protocolo
  `ReadingSessionLiveActivityUpdating` (`any ReadingSessionLiveActivityUpdating`, sin tipos de
  ActivityKit en la firma) y solo lo construye detrás de `#available` — con esto la app sigue
  compilando y corriendo en su piso real de 16.0, sin necesitar subirlo. El protocolo aísla toda
  la superficie de ActivityKit en dos archivos y, de paso, es lo que permite sustituirlo por un
  fake en los tests de fase 2 — real ActivityKit no se puede conducir ni observar desde un test
  unitario.
- **El `Info.plist` de la app dejó de generarse solo.** Hacía falta un esquema de URL propio
  (`CFBundleURLTypes`) para el enlace de "Detener", y esa es una estructura —un arreglo de
  diccionarios— que la generación automática de Xcode no expone por build settings. Pasó a ser
  un archivo físico, con las claves que antes ponía Xcode solas escritas a mano con las mismas
  variables de sustitución que usa su plantilla clásica.
- **La extensión no comparte los tokens de diseño de la app.** La isla dinámica es diminuta y ya
  vive sobre el negro del sistema; se apoya en materiales del sistema e íconos SF Symbols, con
  tipografía `.rounded` para el aire de familia, sin arrastrar `AppColor`/`AppFont` a un segundo
  target por unas pocas líneas de texto.

## Criterios de aceptación

- [x] Con la app en segundo plano y una sesión con tiempo corriendo, la isla dinámica compacta
      muestra el tiempo, y sigue moviéndose sola
- [x] Al mantener presionada, la vista expandida muestra libro, tiempo y el botón de detener
- [x] Pausar desde la app deja el número de la isla congelado
- [x] Tocar "Detener" abre la app directo al modal de página
- [x] Lo mismo funciona para una sesión libre — visto en pantalla: compacta con icono y "00:01"
      contando hacia arriba, expandida con título, tiempo y "Detener"
- [x] Reanudar retoma el número — visto en pantalla: pausada, dos capturas con tres segundos de
      diferencia muestran el mismo valor congelado (`09:58` en ambas); reanudada, el mismo par
      muestra el número bajando (`9:54` → `9:51`)
- [x] Terminar la sesión desde dentro de la app cierra la Live Activity — visto en pantalla: tras
      guardar la página final, la captura de la pantalla de inicio no muestra ninguna isla
- [x] Se ve bien en español y en oscuro/claro — confirmado en español (todas las capturas).
      Claro/oscuro no aplica del mismo modo que en el resto de la app: la isla dinámica siempre
      se dibuja sobre negro, la decide el sistema, no la apariencia del dispositivo — es la misma
      razón por la que la extensión no usa `AppColor`/`AppFont`.

El criterio sobre un dispositivo sin isla dinámica se quitó de esta lista: la propia sección
"No entra" de este documento ya lo excluye del alcance (ahí la Live Activity sigue existiendo en
la pantalla de bloqueo, con el camino estándar de ActivityKit, sin código propio que verificar).
Estaba en ambos lados por descuido de la fase 1; queda solo donde corresponde.

El inglés del widget queda como hueco conocido, no como criterio incumplido silenciosamente — ver
el hallazgo correspondiente más abajo sobre por qué no se pudo verificar en pantalla en esta
pasada.

Los ítems marcados como cubiertos por test pero no vistos en pantalla en la fase 1 se
verificaron en pantalla en esta pasada (fase 3), con la suite de UI desechable
`ZZDynamicIslandVisualCheckUITests`, ya borrada del repositorio tras revisar las capturas. Queda
un hueco honesto, explicado arriba: la verificación visual del inglés en el propio widget — se
intentó dos veces con el idioma del simulador realmente cambiado a inglés (no solo el argumento
de arranque) y las dos veces la isla salió vacía, sin contenido; ver hallazgo. El cambio se cierra
igual: el string en inglés existe y está correctamente cargado en el catálogo
(`tomotecaWidget/Localizable.xcstrings`), el mecanismo de localización es el mismo que ya se
verificó funcionando para español, y lo que falló fue renderizar la Live Activity tras forzar dos
reinicios seguidos del simulador — no algo que hable del código de este cambio.

## Cómo se validó

**De extremo a extremo, de verdad, con la app en segundo plano real** (no un test que simula
estar en segundo plano): arrancar una sesión, mandar la app a segundo plano con
`XCUIDevice.shared.press(.home)`, y capturar la pantalla — la isla compacta mostró el ícono y el
tiempo corriendo solo. Mantener presionada la isla vía SpringBoard mostró la vista expandida con
el libro, el tiempo y "Detener". Tocar "Detener" abrió la app **directo en el modal "¿En qué
página vas?"**, con la página ya prellenada — el resultado exacto que se pidió. Pausar desde la
app y volver a segundo plano mostró el número quieto en la isla cuatro segundos después, sin
moverse.

Todo esto con pruebas de UI desechables, borradas después de mirar las capturas — no quedan en
el repositorio. Los tests que sí quedaron son los de fase 2, descritos abajo.

**Build y suite completa (fase 1):** compila la app, la extensión, y la app con la extensión
embebida. Instalación y arranque en limpio comprobados dos veces (antes y después de crear el
target). La suite completa (199 unitarios, 43 de UI) se corrió tres veces durante la fase 1 —
tras migrar el `Info.plist`, tras crear el target, y tras subir el target de la extensión a iOS
16.2 — sin ninguna regresión.

**Fase 2 — tests unitarios añadidos:**

- `ReadingSessionLiveActivityControllerTests`: cuatro casos sobre `contentState(for:)`, la única
  parte pura del controlador — corriendo con plan (llega `endDate`), pausada con plan (sin
  `endDate`, tiempo restante congelado), libre corriendo (congelado en lo transcurrido) y libre
  pausada. No cubre `start`/`update`/`end` en sí: piden un `Activity` real, que un test unitario
  no tiene cómo conducir ni observar.
- `ActiveSessionControllerTests`, sección "Live Activity": arrancar pide la actividad con el
  libro y la sesión correctos; pausar y reanudar empujan una actualización cada uno, y varios
  refrescos del cronómetro entre medio no empujan ninguna (el número corre solo, sin ayuda);
  terminar y descartar cierran la actividad; recuperar una sesión tras relanzar la app no vuelve
  a arrancarla (ver hallazgo de abajo, sí la reconecta).
- Para hacerlo posible sin tocar ActivityKit de verdad: `ReadingSessionLiveActivityController`
  ganó un protocolo (`ReadingSessionLiveActivityUpdating`) y un reloj inyectable (`now`);
  `ActiveSessionController` pasó de sostener `Any?` con `as?` a sostener
  `any ReadingSessionLiveActivityUpdating`, construido por una factory inyectable
  (`makeLiveActivity`) — en producción apunta a la implementación real detrás de
  `#available(iOS 16.2, *)`, en tests a `FakeLiveActivityUpdating`.

**Suite completa tras fase 2:** 209 tests unitarios (10 nuevos), verde. Suite de UI no vuelta a
correr completa en fase 2 — el cambio de esta fase es solo tests unitarios y un archivo de
producción (`attach`), sin tocar ninguna vista.

**Fase 3 — pasada visual de los huecos que quedaban:** una suite de UI desechable,
`ZZDynamicIslandVisualCheckUITests` (borrada tras revisar sus capturas, no forma parte del
repositorio), cubrió en pantalla real los tres criterios que en fase 2 solo tenían test unitario:

- Sesión libre: compacta con "00:01" contando hacia arriba, expandida con título y "Detener".
- Pausar/reanudar: dos capturas separadas por tres segundos en pausa muestran el mismo valor
  (`09:58` en ambas); el mismo par ya reanudado muestra el número bajando (`9:54` → `9:51`).
- Terminar desde dentro de la app: tras guardar la página final, la isla ya no aparece.
- De paso, español expandido: título, tiempo y "Detener" correctos.

**Suite completa tras fase 3:** la corrida de fase 2 (209 tests) había terminado en
`** TEST FAILED **` pese a que cada suite individual reportaba 0 fallos — ver hallazgo del
scheme más abajo. Con el esquema corregido, una corrida limpia y completa
(`xcodebuild ... test`) terminó en **209 tests unitarios + 48 de UI, 0 fallos,
`** TEST SUCCEEDED **`**. El cambio queda cerrado.

## Hallazgos

- **La API de ActivityKit que hace falta pide 16.2, no 16.1** — un descubrimiento tardío, en
  tiempo de compilación, no de investigación previa. El plan original decía 16.1 con fuentes que
  lo respaldaban; esas fuentes hablaban de cuándo existe ActivityKit, no de cuándo existe la
  forma concreta de la API (`ActivityContent`) que se necesitaba. Corregido en este documento.
- **Migrar el `Info.plist` de generado a físico rompió el bundle en el primer intento**, y de un
  modo que un build exitoso no habría delatado: faltaban `CFBundleIdentifier`,
  `CFBundleExecutable` y el resto de claves que Xcode agrega solo cuando genera el archivo, pero
  no cuando se le da uno propio. El error solo apareció comparando el `Info.plist` final
  claves por clave contra el que había antes — nunca habría saltado con solo mirar que
  "compiló".
- **Un archivo dentro de una carpeta sincronizada no se puede excluir de un build phase
  apuntando la excepción al build phase.** Dos intentos fallaron: uno rechazado en tiempo de
  validación (`PBXResourcesBuildPhase` no es un tipo válido para esa excepción), otro que hizo
  fallar a la gema al guardar (un `PBXSourcesBuildPhase` sin la propiedad `name` que el
  serializador da por hecha). Lo que sí funciona es apuntar la excepción al **target**
  (`PBXFileSystemSynchronizedBuildFileExceptionSet`, no la variante con `buildPhase`) — que
  además es justo lo que la documentación de Apple describe como "Target Membership" en el
  inspector de archivos, solo que sin ese nombre.
- **La gema `xcodeproj` creó el target sin errores** — build phases, Info.plist propio,
  identificador de bundle, dependencia con la app, embeberlo — todo funcionó al primer intento
  una vez resuelto lo del `Info.plist`. El único ajuste que hizo falta después fue habilitar
  `STRING_CATALOG_GENERATE_SYMBOLS` en el target nuevo, que la gema no activa por defecto.
- **Escribir el test de "pausar una sesión recuperada" encontró un bug real, no solo de test.**
  `prepareViewModelIfNeeded()` —el camino que arma el ViewModel cuando la app se relanza con una
  sesión ya corriendo— nunca reconectaba `liveActivity` con la actividad que ya existe del lado
  del sistema; deliberadamente no la vuelve a pedir (correcto: `Activity.request` no es para una
  sesión que no es nueva), pero tampoco guardaba ninguna referencia a la que ya había. El efecto:
  pausar o reanudar una sesión recuperada tras matar la app no llegaba a empujar nada a la isla,
  aunque la actividad siguiera viva en el sistema — el número se habría quedado corriendo mal.
  Arreglado añadiendo `attach(stored:)` al protocolo (`Activity<...>.activities.first`, válido
  porque solo puede haber una sesión activa a la vez en toda la app) y llamándolo desde
  `prepareViewModelIfNeeded()`. El test que lo encontró (`pausingARecoveredSessionStillUpdates`)
  falló primero contra el código sin el fix, confirmando que de verdad lo cubre.
- **La documentación decía que la app entera había subido a iOS 16.2; el proyecto real dice
  16.0.** `CLAUDE.md` y este documento afirmaban que los tres targets originales subieron su piso
  junto con la extensión nueva — quedó así escrito en la fase 1, pero no es lo que hay en
  `project.pbxproj`: la app y los dos targets de test siguen en 16.0, solo `tomotecaWidget` está
  en 16.2. Coincide con lo que Sergio pidió ("no, buscar otra forma" al preguntar por subir a
  16.1) y es la solución más limpia — encontrado al compilar un test nuevo contra
  `ReadingSessionLiveActivityController` con el piso equivocado en la cabeza, y confirmado
  leyendo los `IPHONEOS_DEPLOYMENT_TARGET` reales del proyecto. Corregido en ambos documentos.
- **Interactuar con SpringBoard desde un test dejó el simulador inestable para el siguiente.**
  Justo después de las pruebas que mantienen presionada la isla dinámica y tocan botones del
  sistema, la siguiente corrida de la suite completa falló en `SessionRecoveryUITests` sin
  motivo aparente — un botón que existía no se encontraba. Repetido solo, sin nada de SpringBoard
  de por medio, pasó limpio dos veces seguidas. No es una regresión del código: es que las
  pruebas desechables de esta fase interactuaron con SpringBoard vía `XCUIApplication(bundleIdentifier:)`,
  y eso deja al simulador necesitando un respiro antes de la siguiente corrida. Vale la pena
  recordarlo si la fase 2 termina escribiendo pruebas permanentes que también manipulen la isla.
- **`** TEST FAILED **` con todas las suites individuales en 0 fallos, dos corridas completas
  seguidas.** Solo se explicó mirando el log crudo, no las líneas filtradas: después de que "All
  tests" terminara en verde, aparecía `Testing failed: tomoteca (50356) encountered an error (The
  test runner hung before establishing connection.)`. Causa: el test plan autogenerado del
  esquema reúne cobertura de código para todos los targets del cierre de build por defecto, y eso
  ahora incluye a `tomotecaWidget` — una extensión que nunca se "lanza" como tal, así que el paso
  de instrumentación de cobertura se queda esperando una conexión que no llega. Arreglado en
  `tomoteca.xcscheme`, acotando la cobertura solo al target de la app
  (`onlyGenerateCoverageForSpecifiedTargets="YES"` + `<CodeCoverageTargets>` con solo `tomoteca`).
- **El truco de `-AppleLanguages` en los argumentos de arranque no llega a la extensión del
  widget.** Confirmado directamente: la prueba de sesión libre lanzó la app con
  `-AppleLanguages (en)`, y aun así la isla mostró "Detener" en vez de "Stop" en sus capturas. La
  extensión de Live Activity es un proceso aparte que el sistema lanza por su cuenta al pedir la
  actividad, no un hijo del proceso de la app — no hereda sus argumentos de arranque, solo ve el
  idioma real del simulador. No es un bug del widget: en un dispositivo real solo hay un idioma de
  sistema, así que app y widget siempre coinciden. Sí es una limitación de esta técnica de prueba:
  verificar el widget en inglés pide cambiar el idioma del simulador entero, no un argumento de
  lanzamiento (ver el hallazgo siguiente sobre el intento de hacerlo así).
- **Cambiar el idioma del simulador entero (no el de la app) dejó la isla vacía, dos veces
  seguidas.** Para intentar cerrar el hueco anterior: `xcrun simctl` con el simulador apagado,
  `defaults write -g AppleLanguages/-AppleLocale` a inglés, reiniciado. Con eso el resto de la
  app sí cambió a inglés (nombres de apps del sistema en la captura, "Files" en vez de
  "Archivos"), pero la propia isla —compacta y expandida— salió sin ícono ni texto, ambas veces,
  pese a que el test pasó sin fallar (no hay ninguna aserción sobre el contenido de la isla en
  sí, solo sobre la app). No se investigó más a fondo: es plausible que sea el mismo tipo de
  inestabilidad de WidgetKit tras reiniciar el simulador dos veces seguidas que ya se documentó
  arriba para SpringBoard, no una regresión de este cambio — el mismo mecanismo mostró contenido
  correcto en español, antes y después de este intento. Se abandonó tras el segundo intento en
  vez de seguir insistiendo, el simulador se devolvió a español (`es-CO`/`en-CO`, locale
  `es_CO`, su estado original), y el hueco del inglés queda documentado como tal en los criterios
  de aceptación en vez de forzarlo.
