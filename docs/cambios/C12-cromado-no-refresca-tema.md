# C12 · La tab bar y el back no seguían el tema al cambiarlo

**Tipo:** Corrección · **Estado:** ⬜ Pendiente — aparcado, ver "Por qué se aparca"

Elegir Claro u Oscuro en Configuración cambiaba las pantallas al momento, pero la tab bar y el
botón de volver se quedaban con la apariencia anterior hasta tocar uno de los dos.

## El fallo

Confirmado con dos capturas de Sergio, en las dos direcciones: contenido en claro con la tab bar
y el back todavía oscuros, y luego contenido en oscuro con la tab bar y el back todavía en
claro. No es un problema de dibujo puntual — el cromado no se entera del cambio hasta que algo
lo obliga a recalcular su aspecto, y tocar la pestaña o el back es exactamente eso.

## Alcance

**Entra**

- Que la tab bar y el back sigan el tema sin tocar nada más
- Un test que lo compruebe

**No entra**

Cualquier otra parte del tema.

## Criterios de aceptación

- [ ] Cambiar el tema con la app abierta actualiza la tab bar y el back sin tocar nada más — no
      conseguido; es un fallo de la plataforma sin corrección disponible, ver más abajo
- [x] El resto de lo que el C11 dejó cerrado sigue funcionando
- [ ] Hay un test que falla con el código anterior — no se consiguió: este simulador no
      reproduce el fallo en ninguna dirección

## Por qué se aparca

Es un fallo real, reproducido dos veces en el iPhone de Sergio. Lo que no hay es una forma de
arreglarlo desde el código de la app:

1. **Es un fallo conocido de la plataforma, no de este proyecto.** Varios hilos del foro de
   desarrolladores de Apple describen el mismo síntoma —una `TabView` o una barra de navegación
   que no sigue un cambio de esquema de color hecho en caliente hasta que algo más fuerza un
   redibujado— reportado contra iOS 18 y siguiendo abierto en iOS 26, con un ingeniero de DTS de
   Apple confirmándolo y sin arreglo ofrecido:
   - [iOS18 SwiftUI Bug: Theme Change Issue](https://developer.apple.com/forums/thread/765029)
   - [Switching from Dark to Light mode does not update the background of `TabView`](https://developer.apple.com/forums/thread/764283)
   - [preferredColorScheme Broken in iOS 18](https://developer.apple.com/forums/thread/763251)
   - [iOS 26+ UITabBar unselected item colors not updating with UITabBarAppearance](https://developer.apple.com/forums/thread/818449)
     — distinto síntoma, misma familia: iOS 26 cambió cómo se puede tocar la apariencia de la tab
     bar y rompió cosas que antes funcionaban.
2. **No se encontró ninguna corrección confirmada**, ni en esos hilos ni en artículos externos
   ([Use Your Loaf](https://useyourloaf.com/blog/overriding-dark-mode/),
   [sarunw.com](https://sarunw.com/posts/how-to-disable-dark-mode-in-ios/)) — los dos coinciden en
   que `overrideUserInterfaceStyle` sobre la `UIWindow` es lo correcto para forzar el tema de toda
   la app, pero ninguno cubre el caso de una `TabView` de SwiftUI cuyo cromado no se entera del
   cambio, y ninguno de los hilos de Apple reporta haberlo resuelto — la respuesta repetida de los
   ingenieros de Apple es "abre un reporte".
3. **Se probó igual, por si acaso ayudaba**, y no ayudó: ver "Lo que se intentó".

## Lo que se intentó

`overrideUserInterfaceStyle` fijado en la `UIWindow`, en `AppAppearance.apply(_:)`, llamado desde
`.onAppear` y `.onChange(of: themeController.theme)` sobre la `TabView`. Un segundo intento le
añadió un `setNeedsLayout()` + `layoutIfNeeded()` forzado justo después, por si lo que faltaba
era el paso de diseño que un toque dispara por accidente. Ninguno de los dos cambió nada:
probados en el iPhone real de Sergio con el build correspondiente ya instalado, las capturas
muestran el mismo patrón — el contenido responde al instante, la tab bar y el back se quedan con
el tema anterior hasta la siguiente interacción.

## Qué se queda en el código

**`overrideUserInterfaceStyle` en la ventana se mantiene**, aunque no arregla lo reportado: es la
forma documentada de forzar el tema en UI que `.preferredColorScheme` no alcanza porque no es
SwiftUI — el selector de fotos, la hoja para compartir. No se retira el `setNeedsLayout()` /
`layoutIfNeeded()` forzado, porque tampoco ayudaba a nada: no hay ninguna fuente que lo respalde
y añadía código sin beneficio demostrado.

`ThemeChromeUITests` se queda en el repositorio: entra a Configuración, cambia el tema y adjunta
una captura sin tocar nada más — el paso exacto del fallo. No puede afirmar que el color esté
mal (XCUITest no lee colores), pero es la forma más rápida de volver a mirarlo el día que se
retome.

## Cómo se validó

**Que nada se rompió, sí:** la suite unitaria completa (173) y `ProfileFlowUITests` +
`ThemePersistenceUITests` (4), todos en verde. El tema se sigue aplicando al contenido, se sigue
guardando y sigue sobreviviendo a matar la app — lo único que no se resolvió es que el cromado de
UIKit lo siga en caliente.

**Que el fallo reportado quedó arreglado, no.** No hay tal validación, y este documento no la
simula.

## Hallazgos

- **El cambio se dio por cerrado la primera vez sin haberlo comprobado en el teléfono de
  Sergio**, que era el único sitio donde el fallo se ve — este simulador no lo reproduce en
  ninguna dirección. Sergio lo señaló y el estado se corrigió.
- **Adivinar una segunda corrección sin buscar primero no era mejor que la primera.** Sergio pidió
  validar en internet en vez de seguir probando a ciegas: la búsqueda encontró en minutos lo que
  una tercera o cuarta ocurrencia no habría encontrado por sí sola — que Apple ya tiene el mismo
  reporte abierto y sin resolver.
- **No todo lo que se ve mal en la app se puede arreglar desde la app.** Cuando la búsqueda
  confirma que es un fallo de la plataforma, sin corrección conocida, la respuesta correcta es
  decir eso con las fuentes delante — no inventar un tercer intento.
