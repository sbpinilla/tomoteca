# Diseño de Tomoteca

Mockups de las pantallas de la v1 y sus notas de implementación.

Este documento cubre **cómo se ve** la app. Qué hace, en qué orden se construye y qué reglas
de producto sigue está en [`../features/README.md`](../features/README.md), que es la fuente
de verdad para el modelo de dominio, los estados y la lista de géneros — aquí no se repiten.

Los valores de color, tipografía y espaciado viven en el código, en
`tomoteca/DesignSystem/Tokens/`. Si un mockup y un token no coinciden, **gana el token**: los
mockups son una referencia visual, no la especificación.

## Pantallas

Cada pantalla está mockeada en los dos modos: `light/` y `dark/`, en PNG y en SVG.

| Pantalla | Feature | Notas de implementación |
|---|---|---|
| `01-baul` · [claro](light/01-baul.png) · [oscuro](dark/01-baul.png) | F4 | `List` con `.insetGrouped`, `.searchable()` sobre título y autor. El filtro de estado es un `Menu`, no un segmented: son cinco opciones contando "Todos". Borrado con `.swipeActions`, botón `+` en `.toolbar` |
| `02-detalle-libro` · [claro](light/02-detalle-libro.png) · [oscuro](dark/02-detalle-libro.png) | F6 | Pantalla compartida por las tres pestañas. La fila "Estado" abre el sheet. El botón "Iniciar sesión de lectura" solo aparece si el estado es *leyendo* |
| `03-cambiar-estado` · [claro](light/03-cambiar-estado.png) · [oscuro](dark/03-cambiar-estado.png) | F6 | **Solo ofrece el siguiente estado**, no los cuatro: el flujo es de un solo sentido. El stepper es decorativo; el único control activo es el botón de avanzar |
| `04-formulario` · [claro](light/04-formulario.png) · [oscuro](dark/04-formulario.png) | F5 | `Form` con secciones. El género es un `Picker` con dos secciones (Ficción / No ficción) más "Otros". El estado inicial **solo se muestra en el alta**, nunca en la edición |
| `05-en-curso` · [claro](light/05-en-curso.png) · [oscuro](dark/05-en-curso.png) | F7 | Filtrado por estado *leyendo*, sin búsqueda ni filtros: es una vista curada, no un listado |
| `06-seleccionar-duracion` · [claro](light/06-seleccionar-duracion.png) · [oscuro](dark/06-seleccionar-duracion.png) | F8 | `.sheet` con `.presentationDetents([.height(320)])`, lanzado desde el detalle |
| `07-sesion-activa` · [claro](light/07-sesion-activa.png) · [oscuro](dark/07-sesion-activa.png) | F8 | Cuenta atrás calculada desde la marca de tiempo de inicio, no acumulando ticks de un `Timer` — así sobrevive al segundo plano. La notificación local se programa al iniciar y se cancela si se pausa o se termina antes |
| `08-pagina-final` · [claro](light/08-pagina-final.png) · [oscuro](dark/08-pagina-final.png) | F8 | **No se puede descartar**: `.interactiveDismissDisabled(true)`, sin botón de cancelar. "Guardar" permanece deshabilitado hasta que la página sea válida |
| `09-seguimiento` · [claro](light/09-seguimiento.png) · [oscuro](dark/09-seguimiento.png) | F9 | Atajos de 7/15/30 días, sin rango personalizado. Los días sin sesión se dibujan en cero, no se omiten. Con iOS 16 se puede usar el framework `Charts` en lugar de barras a mano |

## Componentes que salen de estos mockups

| Componente | Dónde aparece |
|---|---|
| `TMCard` | El contenedor redondeado de listas, formularios y tarjetas de estadística |
| `TMStatusChip` | Punto de color + texto del estado. **Sin fondo ni borde** |
| `TMButton` | Primaria (cápsula rellena de acento) y secundaria (borde sobre `surface`) |
| `TMTextField` | Filas del formulario, con etiqueta arriba y valor abajo |
| `TMEmptyState` | Aún sin mockear |

Elementos que también se repiten y merecen componente cuando aparezca el segundo uso:
la barra de progreso del detalle, la tarjeta de estadística de Seguimiento y el selector
segmentado de rango.

## Tipografía

SF Pro Rounded en todo. Los roles de `AppFont` se alinean con estos mockups:

| Rol | Estilo | Uso en los mockups |
|---|---|---|
| `title` | `.title2` bold | "Baúl", "Seguimiento" |
| `headline` | `.subheadline` semibold | Título del libro en una fila |
| `body` | `.body` | Etiquetas de controles |
| `footnote` | `.footnote` | Autor, género, "Página 210 de 340", ejes de la gráfica |

## Reconciliación con los tokens

El kit venía con una paleta que no coincidía con la que ya estaba en Xcode. Se resolvió así:

1. **Modo oscuro cálido.** Se mantiene "Literary Warmth" (`#1B1815`, `#242019`, `#35302A`,
   `#F3EDE4`, `#A6998C`) y se descarta el oscuro neutro del kit. Rima con el crema `#FAF6F0`
   del modo claro, y los mockups apenas cambian. **Los PNG de `dark/` siguen mostrando el
   oscuro neutro** (`#121212`, `#1E1E1E`…) — están un punto por detrás del código en ese
   detalle. El modo claro sí coincide exactamente.
2. **El estado es solo color de texto**, como en los mockups. Se eliminaron los cuatro color
   sets de fondo tintado; `AppColor.Status` expone ahora un color por estado, no un par.
3. **Se añadió el token `track`** (`#F0EAE0` / `#1F1B17`) para el fondo del selector segmentado
   y la parte no rellena de la barra de progreso, que no existía en los tokens.

## Pendiente de mockear

- `TMEmptyState` para el Baúl y En curso sin libros
- El gesto de borrado con swipe
- Las hojas de permisos de cámara, galería y notificaciones
