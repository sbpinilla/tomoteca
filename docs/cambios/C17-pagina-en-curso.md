# C17 · La página actual en "En curso"

**Tipo:** Mejora · **Estado:** ✅ Cerrado

La fila de un libro en la pestaña "En curso" mostraba la barra de progreso y el porcentaje, pero
no la página en la que va — había que entrar al detalle del libro para verla.

## Alcance

**Entra**

- Una línea nueva debajo de la barra, con "Página X de Y" — mismo formato y misma clave de
  localización que ya usa el detalle del libro.
- El porcentaje que ya estaba junto a la barra se queda igual — no se reemplaza, conviven los
  dos.

## Decisión

**El porcentaje se queda, la página se agrega.** Se preguntó explícitamente: la alternativa era
que la página reemplazara al porcentaje junto a la barra. Sergio prefirió conservar los dos — el
porcentaje da una lectura rápida de un vistazo, la página da el dato concreto para quien ya sabe
por dónde iba.

## Cómo funciona

`InProgressRowView` reutiliza la clave `book_detail.page_progress` ("Page %1$lld of %2$lld") que
ya existía para el detalle del libro — el texto no tiene nada específico de esa pantalla, así que
no hacía falta una clave nueva. Una `TMText` más, debajo del `HStack` de la barra y el
porcentaje, dentro del mismo `VStack` — no un componente nuevo.

## Criterios de aceptación

- [x] La fila de un libro en "En curso" muestra "Página X de Y" debajo de la barra
- [x] El porcentaje junto a la barra sigue ahí, sin cambios
- [x] Visto en español y en oscuro, además de inglés y claro

## Cómo se validó

Fase 1: build limpio y una captura de pantalla real de la pestaña "En curso" con un libro
sembrado — confirma la línea nueva bajo la barra y el porcentaje intacto junto a ella.

**Fase 2:** cubierto por `testInProgressRowShowsTheCurrentPageBelowTheBar` en
`ReadingSessionFlowUITests` (fila de "En curso" muestra "Page 210 of 340"). Sin lógica propia que
cubrir a nivel unitario — `book.currentPage`/`book.pageCount` ya estaban probados, y este cambio
es solo layout. Suite completa verde (216 unitarios, toda la de UI). Verificado también en
español y apariencia oscura, con captura: la línea de página y el porcentaje conviven bien en las
dos.

## Hallazgos

Ninguno — cambio de una línea, reutilizando una clave de localización ya existente.
