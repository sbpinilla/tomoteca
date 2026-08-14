# C11 · Elegir el tema desde Configuración

**Tipo:** Feature · **Estado:** ✅ Cerrado

El perfil gana una pantalla de configuración, y en ella se elige claro, oscuro o automático.

## Por qué

La app tiene los dos modos desde el primer día, pero solo obedece al sistema. Quien tiene el
teléfono en automático y lee de noche no puede dejar Tomoteca en oscuro sin cambiar el teléfono
entero.

## Alcance

**Entra**

- Una fila de **Configuración** en el perfil, con su pantalla
- Dentro, el tema: automático (por defecto), claro u oscuro
- Que la elección se recuerde entre arranques

**No entra**

Cualquier otro ajuste. La pantalla nace con uno solo; es el sitio donde caerán los siguientes.

## Cómo funciona

```
Perfil
┌───────────────────────────────┐
│  Mis libros                 › │
│  Configuración              › │
└───────────────────────────────┘

Configuración
   Apariencia
┌───────────────────────────────┐
│  Automático │ Claro │ Oscuro  │
└───────────────────────────────┘
   Automático sigue al sistema.
```

- **Automático es lo predeterminado**, y es lo que hace hoy la app: seguir al teléfono.
- **Se aplica al instante**, en toda la app y no solo en la pantalla de configuración.
- **Se recuerda**, y la app arranca ya con el tema elegido.

## Decisiones

- **El tema se aplica en la raíz, no pantalla por pantalla.** Un `preferredColorScheme` sobre la
  `TabView` alcanza también a las hojas y a la sesión a pantalla completa, que se presentan desde
  dentro. Repartirlo por pantallas dejaría alguna fuera, y sería la de la sesión.
- **La preferencia vive en `Core/`, no en el perfil.** La cambia el perfil pero la aplica la raíz,
  y lo que dos partes comparten no puede pertenecer a una de ellas.
- **Se guarda en `UserDefaults`**, como la estantería del baúl (#29): es una preferencia de la
  interfaz, no un dato de la biblioteca, y no tiene nada que hacer en Core Data.
- **Tres opciones en un segmentado, no un interruptor.** "Oscuro sí/no" no puede expresar
  "automático", que es justamente el valor por defecto.

## Criterios de aceptación

- [x] El perfil tiene una fila de Configuración que abre su pantalla
- [x] La pantalla ofrece automático, claro y oscuro, con automático marcado de inicio
- [x] Elegir claro u oscuro cambia la app entera al momento
- [x] El cambio alcanza a las hojas y a la pantalla de sesión
- [x] Volver a automático devuelve el control al sistema
- [x] La elección sobrevive a cerrar y abrir la app
- [x] Se ve bien en español e inglés

## Cómo se validó

**En el `ThemeController`**, con una suite de `UserDefaults` por test: que sin nada guardado
arranca en automático y no fuerza nada; que elegir escribe; que un controlador nuevo sobre los
mismos defaults —que es lo que hace el siguiente arranque— lee lo elegido; que volver a
automático también se guarda; que un valor imposible cae en automático en vez de romper; y que
**leer la preferencia no la escribe**, para que "nunca elegido" y "elegido automático" sigan
siendo lo mismo.

**En la pantalla, con tests de UI:** que Configuración abre y ofrece las tres opciones con
automático marcado, y que elegir Oscuro queda elegido y deja la app en pie al volver atrás.

**Que la elección sobrevive a matar la app**, en una clase aparte que corre **sin**
`-useInMemoryStore` — esa bandera borra el tema al arrancar justo para que los tests no se
hereden entre sí, que es lo contrario de lo que aquí se prueba. Deja el simulador en automático
al terminar.

Ese test se comprobó rompiendo el cableado a propósito: con el `ThemeController` de la app
creado sobre una suite nueva en cada arranque, falla con "the app opened having forgotten the
theme". No es un verde vacío.

**Lo que ningún test afirma:** que la app *se ve* oscura. XCUITest lee el árbol de accesibilidad,
no colores. Eso se comprobó a mano —preferencia escrita en los defaults del simulador, simulador
en oscuro, app arrancando en claro, incluida la barra de navegación, que era la duda porque
`AppAppearance` fija sus colores por UIKit al arrancar— y queda una captura adjunta a los tests
para revisarlo a ojo.

Suite completa: 173 tests unitarios y 34 de UI, todos en verde.

## Hallazgos

- **Los previews escribían en la preferencia de verdad.** Construían el controlador sobre
  `UserDefaults.standard`, así que abrir un preview en Xcode cambiaba el tema de quien lo estaba
  mirando. Hay un `ThemeController.preview` sobre una suite aparte.
- **`-appTheme 1` como argumento de lanzamiento no sirve para probar esto.** El dominio de
  argumentos guarda el valor como texto y la lectura como `Int` falla, así que la app parecía
  ignorar la preferencia cuando lo que fallaba era la comprobación. Escribirlo con
  `simctl spawn booted defaults write` sí vale.
- **La barra de navegación aguanta el cambio sin tocar `AppAppearance`.** Sus colores se fijan en
  UIKit al arrancar, pero salen de conjuntos del catálogo de assets, así que el `UIColor` es
  dinámico y se resuelve con el tema forzado.
