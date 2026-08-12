# Hito 0 · Andamio

**Estado:** ✅ Cerrado

Dejar el proyecto con la estructura de carpetas definitiva y las tres pestañas navegables,
sin ninguna funcionalidad todavía. Es el esqueleto sobre el que se cuelga todo lo demás.

## Alcance

**Entra**

- La estructura `App/`, `Core/`, `Features/`, `DesignSystem/` de `CLAUDE.md`
- El `TabView` raíz con En curso, Seguimiento y Baúl, con sus SF Symbols
- Una pantalla marcador de posición por pestaña, con su título localizado
- La limpieza de los restos de la plantilla de Xcode

**No entra**

Nada de datos: ni entidades, ni repositorios, ni listados. El modelo de Core Data queda vacío
a propósito, y se puebla en el Hito 1.

## Decisiones

- Orden de las pestañas: **En curso, Seguimiento, Baúl**, con el Baúl a la derecha aunque sea
  la pantalla más completa. Así lo fijan los mockups.
- Iconos: `book`, `chart.bar` y `archivebox`.
- Cada pestaña arranca con su propio `NavigationStack`, para que el estado de navegación de
  una no arrastre al de las otras.
- El título de barra usa la tipografía del sistema por ahora. Ajustarlo a SF Pro Rounded
  requiere tocar `UINavigationBarAppearance`, y eso llega en el Hito 1 con la pantalla real.

## Criterios de aceptación

- [x] La app compila y arranca en el simulador
- [x] Se ven las tres pestañas, con sus iconos, y se puede navegar entre ellas
- [x] Cada pestaña muestra su título, y los títulos cambian al pasar de español a inglés
- [x] Las pantallas se ven correctas en modo claro y en modo oscuro
- [x] No queda rastro de `ContentView`, de la entidad `Item` ni de sus strings en el catálogo
- [x] Los archivos están en `App/`, `Core/` y `Features/`

No aplican los tests que exige la definición de cerrado: este hito no introduce ni ViewModels
ni repositorios. Los primeros llegan en el Hito 1.

## Cómo se validó

Instalada en el simulador de iPhone 17 y lanzada tres veces, forzando idioma con
`-AppleLanguages` y apariencia con `simctl ui`:

- **Español, claro** — "En curso · Seguimiento · Baúl", fondo crema `#FAF6F0`
- **Inglés, claro** — "In progress · Tracking · Trunk", mismos iconos
- **Español, oscuro** — fondo cálido `#1B1815`, la pestaña activa en coral

## Hallazgos

- Al quitar `ContentView` salió a la luz que el `managedObjectContext` se estaba inyectando en
  el environment de SwiftUI, algo que contradice la regla de que las vistas no conocen Core
  Data. Se eliminó la inyección: el contenedor lo usarán solo los repositorios.
- El simulador corre iOS 26, así que la `TabView` se dibuja con la barra flotante nueva del
  sistema, distinta de la de los mockups. No es un fallo: es la apariencia nativa de la
  versión, y conviene decidir en el Hito 1 si se acepta tal cual.
- El título de barra sale con la tipografía del sistema, no con SF Pro Rounded. Queda
  pendiente para el Hito 1, cuando haya una pantalla real donde ajustarlo.
