# C01 · Confirmar antes de borrar

**Tipo:** Mejora · **Estado:** ✅ Cerrado

Borrar un libro pasa a pedir confirmación, y deja de llevarse por delante su historial de
lectura.

## Por qué

En el Hito 5 se decidió que deslizar era gesto suficiente y no hacía falta confirmar. Con la app
en uso queda claro que no: el borrado es irreversible y estaba a un deslizamiento de distancia.

Y hay algo peor de fondo. Hoy la sesión de lectura cuelga del libro con **borrado en cascada**,
así que eliminar un libro borra también sus sesiones y el tiempo leído desaparece de la gráfica
hacia atrás. Eso contradice para qué existe la app: **lo que se quiere medir es el tiempo
invertido en leer, no qué libros se terminaron.** Una tarde de lectura no deja de haber ocurrido
porque el libro se quite del baúl.

## Alcance

**Entra**

- Alerta de confirmación al deslizar para borrar
- `bookID` como campo propio de la sesión, en lugar de derivarse de la relación
- La regla de borrado pasa de cascada a anular: las sesiones sobreviven al libro
- Migración de los datos que ya existan en el dispositivo

**No entra**

Deshacer un borrado, y borrar desde el detalle. Sigue estando solo en el deslizamiento.

## Decisiones

- **La alerta nombra el libro**, para que se vea qué se está borrando y no solo que se está
  borrando algo.
- **El deslizamiento sigue siendo el del sistema**, con su botón redondo de papelera. Un primer
  intento lo sustituyó por una acción propia con la palabra "Eliminar", y se perdió el aspecto
  nativo: ahora `onDelete` sigue ahí, pero en vez de borrar en el acto nombra el libro para la
  alerta, y la fila vuelve a su sitio si la respuesta es no.
- **El botón de borrar es destructivo y el de cancelar es el predeterminado**, así que un toque
  distraído no destruye nada.
- **Las sesiones sobreviven al libro.** El tiempo leído sigue contando en Seguimiento aunque el
  libro ya no esté.
- **La alerta no menciona las sesiones**, precisamente porque ya no se pierden: contarlo solo
  sembraría la duda de si se van a perder.
- **El `bookID` se guarda en la propia sesión.** Hoy se lee de la relación, que al anularse
  dejaría la sesión sin forma de decir a qué libro perteneció.

## Migración

El modelo cambia, y puede haber datos reales en el dispositivo. Core Data infiere sola una
migración ligera al añadir un campo y cambiar una regla de borrado, pero **deja el `bookID`
nuevo vacío en las sesiones existentes**. Hace falta un relleno al arrancar: para cada sesión
sin `bookID`, copiarlo de la relación que todavía apunta a su libro.

## Criterios de aceptación

- [x] Deslizar y pulsar borrar abre una alerta con el título del libro
- [x] Cancelar deja el libro en su sitio
- [x] Confirmar borra el libro
- [x] Las sesiones del libro borrado siguen contando en Seguimiento
- [x] Las sesiones ya guardadas antes del cambio conservan su libro
- [x] La alerta se ve en los dos idiomas
- [x] Hay tests del borrado con sesiones conservadas y del relleno de `bookID`

## Decisiones de producto que toca

Actualiza la lista de [`../features/README.md`](../features/README.md): reemplaza la regla de
borrado sin confirmación fijada en el [Hito 5](../features/hito-5-pulido-baul.md) y precisa la
decisión #17 sobre el histórico de sesiones.

## Cómo se validó

**Tests de UI:** deslizar y confirmar borra el libro y solo ese; deslizar y cancelar lo deja
donde estaba. La alerta se comprueba por su texto, con el título del libro dentro.

**Visualmente:** el deslizamiento conserva el botón redondo del sistema.

**Migración:** el relleno de `bookID` se ejecuta al arrancar sobre las sesiones que no lo
tengan. En el dispositivo de Sergio no hay sesiones que migrar, pero el paso queda escrito y
la migración automática se declara de forma explícita en vez de confiar en los valores por
defecto.
