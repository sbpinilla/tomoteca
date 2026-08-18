# C14 · Pantalla de bienvenida, y el arranque en negro

**Tipo:** Feature · **Estado:** ✅ Cerrado

Tres pantallas que presentan la app la primera vez que se abre, y el instante en negro al
arrancar.

## Por qué

Dos pedidos juntos, sin relación entre sí más que llegar en el mismo mensaje:

1. Quien abre Tomoteca por primera vez cae directo en una biblioteca vacía, sin que nadie le
   cuente qué hace la app.
2. Al arrancar, hay un instante donde la pantalla se ve negra antes de que aparezca la app.

## Diagnóstico del arranque en negro

No es una demora de verdad — es una pantalla de lanzamiento sin personalizar. El proyecto usa la
generada automáticamente por Xcode (`UILaunchScreen_Generation`, sin storyboard), y sin un color
de fondo indicado, esa pantalla usa `systemBackground`: blanco en claro, **negro casi puro en
oscuro**. Como el fondo real de la app (`AppColor.background`) es un marrón cálido, no negro, el
salto entre las dos se nota como "queda en negro un momento", aunque el arranque en sí sea
instantáneo.

Se corrige apuntando la pantalla de lanzamiento al mismo color set que ya usa
`AppColor.background`, para que sea del mismo color que la primera pantalla real y el salto deje
de notarse. Cómo, exactamente, terminó siendo distinto de lo planeado — ver "Hallazgos".

## Alcance

**Entra**

- Tres pantallas de bienvenida, solo la primera vez que se abre la app
- Deslizables, con puntos de página, un botón de saltar y uno de comenzar en la última
- El color de la pantalla de lanzamiento, para que no se note el salto

**No entra**

- Un logo o imagen en la pantalla de lanzamiento — solo el color, que es lo que resuelve lo que
  se reportó. Una imagen es una mejora aparte, no esta corrección.
- Ilustraciones a medida como las de la referencia: el proyecto no tiene un componente para eso,
  y añadirlo es un cambio de diseño mucho más grande que esta pantalla. Se construye con los
  mismos bloques que ya existen — ícono grande, título, texto — como ya hace `TMEmptyState`.

## Cómo funciona

```
┌─────────────────────────────┐      ┌─────────────────────────────┐
│                      Saltar │      │                      Saltar │
│                              │      │                              │
│           📦                │      │           📊                │
│                              │      │                              │
│     Organiza tu biblioteca  │      │     Sigue tu progreso       │
│  Marca qué quieres comprar, │      │  Cada sesión queda           │
│  qué compraste, qué lees y  │      │  registrada: cuánto          │
│  qué terminaste.             │      │  avanzaste y cuánto leíste.  │
│                              │      │                              │
│         ●  ○  ○              │      │         ○  ○  ●              │
│                              │      │    [ Comenzar ]              │
└─────────────────────────────┘      └─────────────────────────────┘
      1 de 3                                3 de 3
```

Tres pantallas, en el orden en que se usa la app:

1. **El baúl** — organizar lo que se quiere leer, lo comprado, lo que se lee y lo terminado.
2. **Las sesiones** — leer con un cronómetro, con tiempo fijo o libre.
3. **El seguimiento** — ver cuánto se ha leído.

Cada una: un ícono grande (el mismo que ya usa su pestaña en la barra), un título y una frase.
"Saltar" está siempre visible y cierra la bienvenida desde cualquier pantalla. En la tercera, en
vez de deslizar hay un botón "Comenzar" que hace lo mismo.

**Solo aparece una vez.** Se guarda que ya se vio, y ni saltarla ni terminarla cambia eso: de las
dos formas, no se vuelve a mostrar.

## Decisiones

- **Se guarda en `UserDefaults`, con un controlador propio** (`OnboardingController`), igual que
  `ThemeController`: una clase mínima, inyectable, con su propia clave. No es un dato de la
  biblioteca, es una preferencia de la interfaz.
- **Los íconos de las tres pantallas son los mismos que ya tienen las pestañas** (`archivebox`,
  `book`, `chart.bar`): la bienvenida no inventa un lenguaje visual nuevo, adelanta el que la app
  ya usa.
- **Bajo `-useInMemoryStore` la bienvenida se da por vista.** Si no, cada una de las decenas de
  pruebas de UI existentes tendría que cruzarla primero — ninguna la espera, y no es lo que están
  probando. Un flag nuevo, `-showOnboarding`, la fuerza a aparecer igual, para las pruebas que sí
  la necesitan.
- **La pantalla de lanzamiento sí lleva un storyboard**, al final — un único `UIViewController`
  con una vista de fondo color `Background`. No era el plan original (ver "Hallazgos"), pero es
  el mecanismo más viejo y probado que hay para esto, y con una sola vista sin nada más no hay
  demasiada superficie que mantener.

## Criterios de aceptación

- [x] La primera vez que se abre la app, aparecen las tres pantallas
- [x] Se puede deslizar entre ellas, con los puntos de página marcando dónde se está
- [x] "Saltar" cierra la bienvenida desde cualquiera de las tres
- [x] "Comenzar" en la tercera hace lo mismo
- [x] Cerrada una vez —de cualquiera de las dos formas— no vuelve a aparecer
- [x] El arranque ya no se ve negro en modo oscuro
- [x] Se ve bien en español e inglés, en claro y en oscuro

## Cómo se validó

**`OnboardingControllerTests`, archivo nuevo:** arranca sin ver la bienvenida; `complete()`
escribe; y que un controlador nuevo sobre los mismos defaults —lo que hace el siguiente
arranque— sigue viéndola como completada.

**`OnboardingFlowUITests`, con `-useInMemoryStore` (que da la bienvenida por vista salvo que se
pida lo contrario) y el nuevo `-showOnboarding` para forzarla:** las tres páginas al deslizar;
que "Comenzar" **no existe** —no solo que esté oculto— antes de la última página; que aparece en
la tercera y entra a la app; y que "Saltar" cierra desde la primera página y desde una del medio.

**`OnboardingPersistenceUITests`, sin `-useInMemoryStore`, como `ThemePersistenceUITests` y
`SessionRecoveryUITests`:** que ni saltarla ni terminarla la traen de vuelta tras matar la app y
volver a abrir de verdad — la única forma de probar que "solo una vez" no es dar por vencida la
palabra ajena.

Al escribir esto se encontró que las dos suites existentes que también renuncian a
`-useInMemoryStore` (`ThemePersistenceUITests`, `SessionRecoveryUITests`) quedaban expuestas a
la bienvenida en un simulador realmente nuevo, sin haberlo probado nunca antes; se les añadió el
mismo gesto defensivo de saltarla si aparece.

Suite completa: 199 tests unitarios (eran 196) y 43 de UI, todos en verde.

## Hallazgos

- **`TMEmptyState` ganó un `Style` (`.compact` / `.hero`) en vez de nacer un componente nuevo.**
  Ya era exactamente "ícono + título + frase"; la bienvenida solo necesitaba una versión más
  grande de lo mismo. Todo lo que ya lo usaba —el baúl, en curso, seguimiento— sigue igual, sin
  tocar una línea, porque `.compact` quedó como valor por defecto.
- **A ese mismo componente le faltaba `.multilineTextAlignment(.center)` en el título** — lo tenía
  el mensaje, pero no el título. Con una sola línea nunca se notaba; en la bienvenida, con
  títulos más largos que en cualquier otro uso del componente, dos de las tres pantallas
  saltaban de línea y el título quedaba alineado a la izquierda, descuadrado bajo el ícono
  centrado. Lo reportó Sergio después de la fase 1; una línea lo arregla, y arregla también
  cualquier otro sitio que llegue a usar el componente con un título largo.
- **`.accessibilityHidden(true)` no bastó para sacar el botón "Comenzar" del árbol de
  accesibilidad** en las dos primeras páginas — seguía apareciendo en las consultas de XCUITest,
  solo que marcado "Disabled", así que un test que esperaba `.exists == false` fallaba. El primer
  intento lo mantenía siempre montado (oculto con opacidad + deshabilitado + accessibilityHidden)
  para reservarle el mismo espacio en las tres páginas y que los puntos de página del sistema no
  quedaran debajo de él. La solución fue sacarlo del `TabView` con `.safeAreaInset(edge: .bottom)`
  y montarlo solo cuando `isOnLastPage` — genuinamente ausente, no oculto — a cambio de un
  pequeño reacomodo al llegar a la última página, que es exactamente cuándo se espera que algo
  nuevo aparezca.
- **La build setting del plan —`INFOPLIST_KEY_UILaunchScreen_UIColorName`— no funcionó, y no fue
  por escribirla mal.** Combinada con `UILaunchScreen_Generation` (lo que ya traía el proyecto),
  el Info.plist generado terminaba con `UILaunchScreen: { UILaunchScreen: {} }` — una clave
  duplicada y vacía — en las cuatro variantes probadas: con y sin sufijos de SDK, con y sin la
  bandera de generación presente a la vez. Probado con una reconstrucción limpia real cada vez,
  no solo leyendo la build setting resuelta. Es un problema de esta versión de Xcode (26.6) con
  esa combinación concreta de claves, documentado también en otros proyectos que generan su
  Info.plist ([issue de Tuist](https://github.com/tuist/tuist/issues/6192)). Se abandonó esa vía
  y se pasó al storyboard clásico, que usa una única clave plana (`UILaunchStoryboardName`) sin
  el mismo punto de fallo.

  Fuentes consultadas para el diagnóstico y la alternativa:
  [Sarunw · How to add Launch Screen in SwiftUI](https://sarunw.com/posts/launch-screen-using-plist/),
  [SwiftLee · Launch screens in Xcode](https://www.avanderlee.com/xcode/launch-screen/),
  [Apple · UIColorName](https://developer.apple.com/documentation/bundleresources/information-property-list/uilaunchscreen/uicolorname).
