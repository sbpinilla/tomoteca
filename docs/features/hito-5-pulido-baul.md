# Hito 5 · Pulido del Baúl

**Estado:** ✅ Cerrado

Hacer el Baúl usable con una biblioteca de verdad: encontrar un libro, filtrar por estado,
corregir lo que se escribió mal y borrar lo que sobra.

## Alcance

**Entra**

- Búsqueda por título y autor
- Filtro por estado
- Borrado con deslizamiento
- Edición de un libro, reutilizando el formulario del alta
- `delete` en el repositorio

**No entra**

Ordenar por otros criterios. El orden sigue siendo por fecha de creación, el más reciente
primero.

## Decisiones

- **La edición no toca el estado.** Es la decisión #16 del README y aquí se hace efectiva: el
  selector de estado inicial solo aparece al dar de alta. Si la edición pudiera cambiarlo, la
  regla de que el ciclo no retrocede tendría una puerta trasera.
- **El formulario es el mismo para alta y edición**, con un modo que decide el título, si se
  muestra el estado y si guarda creando o actualizando. Dos formularios paralelos se
  desincronizan en cuanto se añade un campo.
- **Búsqueda y filtro se combinan**: filtrar por "Leyendo" y luego buscar deja la búsqueda
  dentro de ese subconjunto, que es lo que espera quien acaba de filtrar.
- **La búsqueda ignora mayúsculas y acentos.** Buscar "garcia" tiene que encontrar a García
  Márquez; exigir la tilde convertiría la búsqueda en un examen de ortografía.
- **El borrado no pide confirmación.** Deslizar ya es un gesto deliberado, y es la convención
  del sistema. Se acepta el riesgo a cambio de no estorbar en el caso habitual.
- **El filtro es un menú, no un segmentado**: son cinco opciones contando "Todos", y no caben.

## Criterios de aceptación

- [x] Buscar por título o por autor reduce la lista
- [x] La búsqueda encuentra sin distinguir mayúsculas ni acentos
- [x] El filtro por estado reduce la lista, y se combina con la búsqueda
- [x] Una búsqueda sin resultados lo dice, en vez de mostrar una lista vacía sin más
- [x] Deslizar una fila permite borrar el libro
- [x] Editar un libro conserva su estado y su portada
- [x] El formulario de edición no ofrece cambiar el estado
- [x] Hay tests de búsqueda, filtro, borrado y edición

## Cómo se validó

**Tests unitarios:** búsqueda por título y por autor, insensible a mayúsculas y acentos en cinco
variantes de "García Márquez"; el filtro por estado; la combinación de ambos; la diferencia
entre biblioteca vacía y búsqueda sin resultados; el borrado; y en la edición, que se rellena
con los valores actuales, que no ofrece el estado, que sobreescribe en vez de duplicar y que
conserva estado, página actual, fecha de creación y portada.

**Tests de UI:** buscar, buscar sin acentos, búsqueda sin resultados, filtrar por estado,
borrar deslizando y editar comprobando que el estado no se mueve.

**En simulador:** el Baúl con su barra de búsqueda y su filtro, en español y modo claro.

## Hallazgos

- **Borrar con un filtro activo apuntaba al libro equivocado.** `onDelete` da posiciones dentro
  de la lista *visible*, que con búsqueda o filtro no coincide con el catálogo almacenado.
  Resolverlas contra el catálogo habría borrado un libro distinto del que se deslizó. Hay un
  test que fija justo ese caso, borrando con el filtro puesto.
- **La barra de búsqueda desaparecía al no haber resultados.** Estaba dentro de la rama que
  dibuja la lista, así que una búsqueda sin coincidencias se llevaba por delante el único
  control capaz de deshacerla. Ahora cuelga de la vista raíz.
- **Vacío no es lo mismo que sin resultados**, y se distinguen con dos mensajes: una biblioteca
  sin libros invita a añadir el primero; una búsqueda fallida invita a cambiar la búsqueda.
