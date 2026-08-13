# C06 · El baúl, una estantería por estado

**Tipo:** Mejora · **Estado:** ✅ Cerrado

El menú de filtro se cambia por una fila de chips, uno por estado, sin opción de verlos todos a
la vez. Y dentro de cada estado, el último libro que llegó ahí sale primero.

## Por qué

Con treinta y cuatro libros dentro, el baúl es un scroll largo donde todo se mezcla: lo que
quieres comprar, lo que tienes sin abrir y lo que ya leíste. Encontrar algo obliga a recorrerlo
entero, y el filtro actual está escondido detrás de un menú que hay que abrir para saber qué
opciones tiene.

Cuatro listas cortas se leen mejor que una larga.

## Alcance

**Entra**

- Una fila de chips, uno por estado, en lugar del menú
- Se quita la opción de ver todos los libros a la vez
- El chip elegido se recuerda entre arranques
- Cada chip muestra cuántos libros tiene
- Dentro de un estado, el último libro que cambió a él sale primero

**No entra**

Ordenar por título o por autor, y agrupar por género. La pregunta que se resuelve es "qué tengo
en este estado", no "cómo ordeno mi biblioteca".

## Cómo quedaría

```
┌────────────────────────────────────────┐
│                                    ＋  │
│  Baúl                                  │
│                                        │
│  🔍 Buscar por título o autor          │
│                                        │
│  ╭─────────╮ ╭──────────╮ ╭─────────╮  │
│  │ Comprar │ │ Comprado │ │ Leyendo │ ›│   ← se desliza
│  │    3    │ │    34    │ │    1    │  │
│  ╰─────────╯ ╰──────────╯ ╰─────────╯  │
│    apagado     SELECCIONADO   apagado  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ ▨  El alquimista              ›  │  │
│  │    Paulo Coelho · Otros          │  │
│  │    ● Comprado                    │  │
│  ├──────────────────────────────────┤  │
│  │ ▨  Meditaciones               ›  │  │
│  │    Marco Aurelio · Otros         │  │
│  │    ● Comprado                    │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ─────  En curso  Seguim.  Baúl  ────  │
└────────────────────────────────────────┘
```

Al mover un libro de *Comprado* a *Leyendo*, desaparece de la primera lista, aparece **el primero**
de la segunda, y los contadores de ambos chips cambian.

**El chip.** Píldora con el color del estado: relleno tenue y texto en su color cuando está
seleccionado, solo texto apagado cuando no. Sin punto — el color ya lo dice todo, y el punto de
`TMStatusChip` distingue estados dentro de una fila, no aquí, donde cada chip es de uno solo.

**La fila se desliza en horizontal.** Cuatro chips con su contador no caben a lo ancho, y menos
con tipografías grandes.

**Las filas no cambian.** Conservan su chip de estado, aunque todas las de una lista lo
compartan: la fila se lee igual en el baúl, en En curso y en los resultados de búsqueda, y esa
constancia vale más que ahorrar una línea.

## Decisiones

- **No hay "Todos".** Es lo que hacía la lista inabarcable. Y con la búsqueda a mano, un vistazo
  global se resuelve buscando, no recorriendo.
- **Siempre hay un estado seleccionado.** No existe el estado "sin filtro"; el baúl siempre está
  mostrando una estantería.
- **El chip elegido se recuerda entre arranques.** Volver siempre al mismo sitio obligaría a
  reelegir cada vez a quien pasa el día en *Leyendo*.
- **La primera vez arranca en *Comprado***, que es donde está el grueso de la biblioteca.
- **Cada chip lleva su contador.** Sin él hay que entrar en cada estantería para saber si tiene
  algo, que es justo el paseo que se quería quitar.
- **Dentro de un estado manda la fecha del último movimiento**, no la de creación. Un libro que
  acabas de marcar como comprado es el que tienes en la cabeza; que aparezca decimoctavo porque
  se registró hace meses es exactamente lo que molesta.
- **El reloj empieza al crear el libro**, no solo al avanzar. Registras un libro y encabeza
  *Comprar*; lo compras y encabeza *Comprado*. Sin esto, un libro recién añadido caería al fondo
  de su primera estantería.
- **La búsqueda sigue actuando dentro del estado elegido**, como hasta ahora con el filtro.

## El modelo cambia

Hace falta saber **cuándo** un libro llegó a su estado actual, y eso hoy no se guarda. Se añade
`statusChangedAt` a `BookEntity` y a `Book`, escrito al crear el libro y reescrito cada vez que
el estado avanza:

```
Registras "Dune" como quiero comprar   →  statusChangedAt = ahora  →  primero en Comprar
Lo marcas como comprado                →  statusChangedAt = ahora  →  primero en Comprado
Empiezas a leerlo                      →  statusChangedAt = ahora  →  primero en Leyendo
```

La migración es ligera —un campo nuevo y opcional—, pero deja el campo vacío en los libros que ya
existen. Se rellena al arrancar con su fecha de creación: no es cuándo se movieron de verdad,
pero es el mejor dato disponible y conserva el orden que había.

## Decisiones de producto que toca

Sustituye la decisión **#18** de [`../features/README.md`](../features/README.md), que fija el
orden del baúl por fecha de creación. Y precisa la **#12**, que da por hecho un filtro por estado
con opción de verlos todos.

## Criterios de aceptación

- [x] Los cuatro estados aparecen como chips, sin opción de "Todos"
- [x] Siempre hay uno seleccionado, y la lista muestra solo ese estado
- [x] Cada chip dice cuántos libros tiene
- [x] La selección sobrevive a cerrar y abrir la app, y la primera vez abre en *Comprado*
- [x] Al avanzar el estado de un libro, aparece el primero en su nueva estantería
- [x] Los libros que nunca se han movido conservan el orden que tenían
- [x] Buscar filtra dentro del estado seleccionado
- [x] Un estado sin libros lo dice, sin confundirse con una biblioteca vacía
- [x] Un libro recién registrado encabeza la estantería de su estado inicial
- [x] La fila de chips se puede recorrer con tipografías de accesibilidad
- [x] La pantalla se ve correcta en los dos idiomas y los dos modos
- [x] Hay tests del orden por último movimiento, del contador y de la selección recordada

## Cómo se validó

**Tests unitarios:** que una estantería muestra solo lo suyo; que hay una por estado y ninguna
de "todos"; el contador por estado y que ignora la búsqueda; la estantería vacía distinguida de
la biblioteca vacía; el arranque en *Comprado* y la selección recordada; la búsqueda dentro de
la estantería abierta; y el orden en tres variantes — última llegada primero, la llegada gana a
la fecha de registro, y un libro sin mover conserva el orden que tenía. En el detalle, que
avanzar reinicia el reloj sin tocar la fecha de registro.

**Tests de UI:** que los chips cambian de estantería, que una estantería que se queda sin libros
lo dice, que borrar en una no toca las demás, y que buscar acentos funciona dentro de la abierta.

**En simulador:** el baúl con los cuatro chips y sus contadores, en español claro e inglés
oscuro.

## Hallazgos

- **Un test que falló destapó un agujero de producto.** Al añadir un libro entra en *Quiero
  comprar*, pero el baúl estaba mirando *Comprado*: guardabas y no pasaba nada visible. Ahora el
  baúl **sigue al libro recién guardado** hasta su estantería. `BookFormViewModel.save()` pasó a
  devolver el libro en vez de un booleano, precisamente para poder hacerlo.
- **La estantería recordada se filtraba entre tests de UI.** Vive en `UserDefaults`, que
  sobrevive al proceso, así que la elección de un test decidía dónde abría el siguiente. Se
  limpia al arrancar cuando la corrida pasa `-useInMemoryStore`.
- **Cuatro tests de UI dejaron de encontrar sus libros**, y no era un fallo: buscaban títulos que
  ahora viven en otra estantería. Ahora eligen la suya antes. Es el coste esperado de partir una
  lista en cuatro.
