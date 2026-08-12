# Hito 1 · Baúl con datos reales

**Estado:** ✅ Cerrado

Primera rebanada vertical completa: desde Core Data hasta la pantalla. Al terminar, el Baúl
muestra libros reales leídos de la base de datos, y el estado vacío cuando no hay ninguno.

## Alcance

**Entra**

- `BookEntity` en el modelo de Core Data
- El modelo de dominio (`Book`, `BookStatus`, `Genre`) y el protocolo `BookRepository`
- `CoreDataBookRepository`, con la conversión de entidades a dominio
- Los primeros componentes: `TMText`, `TMCard`, `TMStatusChip`, `TMEmptyState`
- El listado del Baúl con su ViewModel
- Datos de ejemplo para poder ver la pantalla llena

**No entra**

Búsqueda, filtro, borrado, alta y detalle. Todo eso llega en los hitos 2 y 5. Aquí la lista
solo se lee y no se toca.

## Decisiones

- **El estado se guarda como entero**, no como texto, para que el orden del ciclo de vida
  (`quiero comprar` → `comprado` → `leyendo` → `leído`) sea el orden natural del campo y las
  comparaciones no dependan de cadenas.
- **El género se guarda como texto**, con el identificador estable de cada caso. Añadir un
  género nuevo no debe reordenar ni invalidar los existentes.
- **Los datos de ejemplo solo se siembran bajo `-seedSampleData`**, un argumento de lanzamiento
  y solo en compilaciones de depuración. Así la app real arranca vacía y muestra el estado
  vacío, que es lo que verá un usuario nuevo.
- **El porcentaje solo se muestra en los libros en curso.** En el resto de estados no aporta
  nada y ensucia la fila.
- **`TMText` distingue texto traducible de dato del usuario.** El título de un libro no pasa
  por el catálogo de strings; una etiqueta de la interfaz, siempre.

## Criterios de aceptación

- [x] La app arranca vacía y muestra el estado vacío
- [x] Con datos sembrados, la lista muestra portada, título, autor, género y estado
- [x] El porcentaje aparece solo en los libros en curso
- [x] La pantalla se ve correcta en los dos idiomas y los dos modos
- [x] Los géneros y los estados están traducidos
- [x] El título de barra usa SF Pro Rounded
- [x] Hay tests del repositorio y del ViewModel

## Cómo se validó

15 tests en verde: dominio (`BookTests`), repositorio sobre un almacén en memoria
(`CoreDataBookRepositoryTests`) y ViewModel contra un doble del protocolo
(`BookListViewModelTests`).

En simulador, tres lanzamientos:

- **Vacío, español, claro** — "Sin libros" con su icono y su mensaje
- **Con datos, español, claro** — cuatro libros, "Leyendo · 62 %" solo en el primero
- **Con datos, inglés, oscuro** — géneros y estados traducidos, fondo cálido

Para capturar la pestaña del Baúl sin poder tocar la pantalla se añadió el argumento de
lanzamiento `-startTab`, solo en compilaciones de depuración.

## Hallazgos

- **Los tests destaparon un parpadeo real.** El repositorio publicaba con
  `receive(on: DispatchQueue.main)`, que salta de ciclo aunque ya se esté en el hilo principal:
  la lista habría dibujado el estado vacío durante un frame antes de recibir los libros. Se
  eliminó el salto y se aisló el repositorio en `@MainActor`, que garantiza el hilo por
  construcción en lugar de por convención.
- **El composition root pedía importar Core Data** solo para sacar el `viewContext` y pasárselo
  al repositorio. Se cambió el inicializador para que reciba el `PersistenceController`: así
  ninguna capa por encima del repositorio conoce Core Data.
- El porcentaje se formatea con `.percent`, que respeta la región del dispositivo. En inglés
  con región española sale "62 %" con espacio; es correcto, no un fallo de formato.
