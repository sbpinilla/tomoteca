# Cambios

Mejoras, correcciones y features posteriores a la v1. Los ocho hitos que construyeron la app
están en [`../features/README.md`](../features/README.md); a partir de aquí el trabajo llega
como cambios sueltos, uno por archivo.

Cada cambio sigue el mismo formato que los hitos: alcance, decisiones, criterios de aceptación,
cómo se validó y hallazgos. Y la misma definición de cerrado: criterios cumplidos, visto en
simulador en los dos idiomas y los dos modos, con tests, y commiteado.

## Dónde vive cada cosa

**Las decisiones de producto viven en un solo sitio**: la lista numerada de
[`../features/README.md`](../features/README.md). Cuando un cambio revierte o añade una
decisión, se edita esa lista y el archivo del cambio explica el porqué.

Los documentos de hito son un **registro histórico**: dicen qué se decidió entonces y no se
reescriben. Si una decisión de un hito ya no está vigente, lo que manda es el README de
features, y el cambio que la movió queda enlazado desde allí.

## Índice

| Cambio | Tipo | Estado |
|---|---|---|
| [C01 · Confirmar antes de borrar](C01-confirmar-borrado.md) | Mejora | ✅ Cerrado |
| [C02 · Retomar una sesión interrumpida](C02-retomar-sesion.md) | Corrección | ✅ Cerrado |
| [C03 · Campos más cómodos de enfocar](C03-campos-comodos.md) | Mejora | ✅ Cerrado |
| [C04 · Tests más rápidos de ejecutar](C04-tests-mas-rapidos.md) | Mejora | ✅ Cerrado |
| [C05 · Perfil, con importar y exportar libros](C05-perfil-importar-exportar.md) | Feature | ✅ Cerrado |
| [C06 · El baúl, una estantería por estado](C06-baul-por-estado.md) | Mejora | ✅ Cerrado |

Estados: ⬜ Pendiente · 🟡 En curso · ✅ Cerrado
