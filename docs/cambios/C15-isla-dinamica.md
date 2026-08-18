# C15 · La sesión en la isla dinámica

**Tipo:** Feature · **Estado:** 🟡 En curso

Con una sesión corriendo y la app en segundo plano, el tiempo se ve en la isla dinámica, con un
botón para detenerla que abre la app directo al modal de página.

## Las dos decisiones que se tomaron antes de escribir código

### 1. El piso de iOS sube a 16.2, no a 16.0

Live Activities existe desde iOS 16.1, pero la forma de la API que se terminó usando
(`ActivityContent`, la que reemplazó a la original dos meses después) pide 16.2 — se descubrió
al compilar, cuando el compilador rechazó `Activity.request(attributes:content:pushType:)` por
pedir 16.2. La app entera sube ese piso mínimo, en los tres targets más el nuevo. No hace falta
llegar a iOS 17: los botones interactivos "de verdad" dentro de una Live Activity
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
  entero.** `ActiveSessionController` lo sostiene como `Any?` y solo lo toca detrás de
  `#available` — es lo que permite que el resto de la app siga compilando y corriendo en un piso
  de 16.0... salvo que ese piso también subió a 16.2, ver la decisión de arriba. Se conserva la
  separación igual: es correcta con independencia del piso final, y aísla toda la superficie de
  ActivityKit en dos archivos.
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
- [ ] Lo mismo funciona para una sesión libre — no verificado aún
- [ ] Reanudar retoma el número — no verificado aún (el mecanismo es el mismo que arrancar, pero
      no se vio en pantalla)
- [ ] Terminar la sesión desde dentro de la app cierra la Live Activity — no verificado aún
- [ ] En un dispositivo sin isla dinámica, la actividad se ve en la pantalla de bloqueo igual —
      no verificado
- [ ] Se ve bien en español e inglés, en claro y en oscuro — solo visto en español

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
el repositorio. Los tests que sí van a quedar están descritos más abajo, pendientes de fase 2.

**Build y suite completa:** compila la app, la extensión, y la app con la extensión embebida.
Instalación y arranque en limpio comprobados dos veces (antes y después de crear el target). La
suite completa (199 unitarios, 43 de UI) se corrió tres veces durante la fase 1 — tras migrar el
`Info.plist`, tras crear el target, y tras subir a iOS 16.2 — sin ninguna regresión.

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
- **Interactuar con SpringBoard desde un test dejó el simulador inestable para el siguiente.**
  Justo después de las pruebas que mantienen presionada la isla dinámica y tocan botones del
  sistema, la siguiente corrida de la suite completa falló en `SessionRecoveryUITests` sin
  motivo aparente — un botón que existía no se encontraba. Repetido solo, sin nada de SpringBoard
  de por medio, pasó limpio dos veces seguidas. No es una regresión del código: es que las
  pruebas desechables de esta fase interactuaron con SpringBoard vía `XCUIApplication(bundleIdentifier:)`,
  y eso deja al simulador necesitando un respiro antes de la siguiente corrida. Vale la pena
  recordarlo si la fase 2 termina escribiendo pruebas permanentes que también manipulen la isla.
