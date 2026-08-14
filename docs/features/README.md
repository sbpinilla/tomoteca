# Features de Tomoteca

Índice de features de la v1, con el estado de cada una y el checklist general de ejecución.
Cada feature recibe su propio archivo en esta carpeta cuando se empieza a construir.

---

## Alcance de la v1

Registro personal de libros, **sin login y sin backend**: todo se guarda en local con Core Data.

Fuera de alcance por ahora: cuentas de usuario, sincronización con iCloud, escaneo de ISBN,
búsqueda en catálogos externos, préstamos, etiquetas libres, recomendaciones, notas o subrayados.

## Estructura de la app

Una `TabView` con cuatro pestañas:

| Pestaña | Contenido |
|---|---|
| **En curso** | Los libros en estado *leyendo*. Punto de entrada a la sesión de lectura. |
| **Seguimiento** | Gráfica de tiempo leído por día, con rango de fechas. |
| **Baúl** | El registro completo de libros: lista, búsqueda, alta, detalle. |
| **Perfil** | Lo que actúa sobre la biblioteca entera. Hoy, importar y exportar. |

## Diseño

Los mockups de las nueve pantallas y sus notas de implementación están en
[`../design/README.md`](../design/README.md). Cada feature de abajo enlaza los suyos.

## Modelo de dominio

**Libro**

| Campo | Obligatorio | Nota |
|---|---|---|
| Título | Sí | |
| Autor | No | Se usa también en la búsqueda |
| Género | Sí | Uno solo, de una lista cerrada precargada (ej. filosofía) |
| Nº de páginas | **Sí** | Obligatorio: sin él no hay porcentaje de avance |
| Portada | No | Foto de cámara o de galería |
| Estado | Sí | Ver abajo |
| Página actual | — | La última registrada en una sesión |

**Sesión de lectura**: libro, inicio, fin, duración planificada, duración real, página final.
Una vez registrada **no se puede borrar**: es el histórico sobre el que se calcula el seguimiento.

### Géneros

Lista cerrada, presentada en el desplegable en dos secciones para que sea fácil de recorrer.

**Ficción** — Novela · Ciencia ficción · Fantasía · Terror · Misterio y suspense · Romántica ·
Novela histórica · Aventura · Poesía · Teatro · Cómic y novela gráfica · Infantil y juvenil

**No ficción** — Filosofía · Historia · Biografía y memorias · Ensayo · Ciencia · Psicología ·
Desarrollo personal · Negocios y economía · Tecnología · Salud y bienestar · Arte y fotografía ·
Viajes · Religión y espiritualidad · Cocina

**Otros** — cierra la lista, para que ningún libro se quede sin poder registrarse.

### Estados y transiciones

```
quiero comprar  →  comprado  →  leyendo  →  leído
```

**El flujo es de un solo sentido: no hay marcha atrás.** Un libro no vuelve a un estado
anterior ni se reabre un *leído* para releerlo.

Al registrar un libro se puede elegir cualquier estado de partida (*quiero comprar* por
defecto), para dar de alta libros que ya se tienen o ya se leyeron. A partir de ahí, solo
avanza. El paso a *leído* es manual desde el selector de estado; si al cerrar una sesión se
registra la última página, la app lo propone.

---

## Features

### F1 — Modelo de datos y persistencia
Entidades de Core Data (`BookEntity`, `ReadingSessionEntity`), modelos de dominio, y los
repositorios que los exponen. Sustituye la entidad `Item` de la plantilla de Xcode.
**Base de todo lo demás.**

### F2 — Componentes base del design system
`TMText`, `TMStatusChip`, `TMCard`, `TMButton`, `TMTextField`, `TMEmptyState`. Se construyen
sobre los tokens ya existentes. Se van creando conforme cada pantalla los pida, no todos de golpe.

### F3 — Navegación raíz
La `TabView` de tres pestañas, con sus iconos SF Symbols y el estado de navegación de cada una.

### F4 — Baúl: listado de libros
Lista con portada, título, autor, género, estado y porcentaje de avance. Barra de búsqueda
nativa por título y autor, filtro por estado, estado vacío ("sin libros"), borrado con swipe
y botón de añadir en la barra de navegación.
→ `01-baul` · [claro](../design/light/01-baul.png) · [oscuro](../design/dark/01-baul.png)

### F5 — Alta y edición de libro
Formulario con portada (cámara o galería), título, autor, género desplegable, número de
páginas y estado inicial. La edición reutiliza el mismo formulario, sin el estado.
→ `04-formulario` · [claro](../design/light/04-formulario.png) · [oscuro](../design/dark/04-formulario.png)

### F6 — Detalle del libro
Portada, título, autor, género, porcentaje de avance y última página leída. Desde aquí se
cambia el estado (sheet con la siguiente transición) y se accede a editar.
**Es la misma pantalla desde las tres pestañas.**
→ `02-detalle-libro` · [claro](../design/light/02-detalle-libro.png) · [oscuro](../design/dark/02-detalle-libro.png)
→ `03-cambiar-estado` · [claro](../design/light/03-cambiar-estado.png) · [oscuro](../design/dark/03-cambiar-estado.png)

### F7 — En curso
Lista de los libros en *leyendo* — pueden ser varios a la vez — con su avance. Desde el
detalle de cada uno se arranca la sesión de lectura.
→ `05-en-curso` · [claro](../design/light/05-en-curso.png) · [oscuro](../design/dark/05-en-curso.png)

### F8 — Sesión de lectura
Selector de duración (10, 15, 30 min), cuenta atrás, pausar y terminar antes de tiempo. El
cronómetro se calcula por marca de tiempo, así que **sobrevive a salir de la app o a una
llamada**, y avisa con una notificación local al terminar. Al cerrar, un modal pide la página
final de forma **obligatoria** y actualiza el avance del libro. Se guarda el tiempo realmente
leído, no el planificado.
→ `06-seleccionar-duracion` · [claro](../design/light/06-seleccionar-duracion.png) · [oscuro](../design/dark/06-seleccionar-duracion.png)
→ `07-sesion-activa` · [claro](../design/light/07-sesion-activa.png) · [oscuro](../design/dark/07-sesion-activa.png)
→ `08-pagina-final` · [claro](../design/light/08-pagina-final.png) · [oscuro](../design/dark/08-pagina-final.png)

### F9 — Seguimiento
Rango de fechas con atajos de 7, 15 y 30 días. Gráfica de barras con los minutos leídos por
día — los días sin lectura aparecen en cero, no se saltan — más el total y el promedio del rango.
→ `09-seguimiento` · [claro](../design/light/09-seguimiento.png) · [oscuro](../design/dark/09-seguimiento.png)

### Transversal
Permisos de cámara, galería y notificaciones (con sus textos de uso localizados),
accesibilidad y soporte de modo oscuro.

**Idiomas: español e inglés.** Ningún texto visible va escrito a mano en el código; todos
pasan por el catálogo de strings. Los mockups están en español, pero cada pantalla que se
construya añade sus dos traducciones en el mismo commit, no después.

---

## Checklist

### Ya hecho

- [x] Proyecto configurado: iOS 16, solo iPhone, solo vertical
- [x] `CLAUDE.md` con arquitectura y reglas del design system
- [x] Tokens: `AppColor`, `AppFont`, `Spacing`, `Radius`
- [x] Paleta "Literary Warmth" en color sets, con variante clara y oscura
- [x] `TokensGallery` como referencia visual
- [x] Mockups de las nueve pantallas en modo claro y oscuro, en `docs/design/`
- [x] Catálogo de strings con español e inglés, y símbolos verificados en compilación

### Hitos

Las features se construyen en rebanadas verticales: cada hito llega hasta la pantalla y se
puede ver funcionando. **No se avanza al siguiente hasta cerrar el anterior.**

| Hito | Qué entra | Estado |
|---|---|---|
| [0 · Andamio](hito-0-andamio.md) | Estructura de carpetas y las tres pestañas vacías | ✅ Cerrado |
| [1 · Baúl con datos reales](hito-1-baul.md) | Core Data, repositorio y el listado | ✅ Cerrado |
| [2 · Alta de libro](hito-2-alta-libro.md) | Formulario, sin portada todavía | ✅ Cerrado |
| [3 · Detalle y estado](hito-3-detalle-estado.md) | Pantalla de detalle y sheet de avance | ✅ Cerrado |
| [4 · Portada](hito-4-portada.md) | Cámara, galería y permisos | ✅ Cerrado |
| [5 · Pulido del baúl](hito-5-pulido-baul.md) | Búsqueda, filtro, borrado y edición | ✅ Cerrado |
| [6 · Sesión de lectura](hito-6-sesion-lectura.md) | En curso, cronómetro y notificación | ✅ Cerrado |
| [7 · Seguimiento](hito-7-seguimiento.md) | Rango de fechas y gráfica | ✅ Cerrado |

Estados: ⬜ Pendiente · 🟡 En curso · ✅ Cerrado

**Un hito solo se marca cerrado** cuando sus tareas están tachadas, se ha visto funcionando en
el simulador **en los dos idiomas y los dos modos**, tiene tests de sus ViewModels y
repositorios, y está commiteado.

Cada hito abre su propio archivo en esta carpeta (`hito-0-andamio.md`…) al empezarlo, con sus
criterios de aceptación concretos, y se cierra anotando cómo se validó.

### Tareas

**Hito 0 · Andamio** — ✅ cerrado
- [x] Reorganizar el proyecto a `App/`, `Core/`, `Features/` según `CLAUDE.md`
- [x] Eliminar los restos de la plantilla: `ContentView`, la entidad `Item` y sus strings
      auto-extraídos del catálogo
- [x] F3 · `TabView` raíz con las tres pestañas y sus SF Symbols
- [x] Títulos de pestaña localizados en español e inglés

**Hito 1 · Baúl con datos reales** — ✅ cerrado
- [x] F1 · `BookEntity` en el modelo de Core Data
- [x] F1 · Modelo de dominio `Book` y protocolo `BookRepository`
- [x] F1 · `CoreDataBookRepository`
- [x] F1 · Lista precargada de géneros
- [x] F2 · `TMText`, `TMCard`, `TMStatusChip`, `TMEmptyState`
- [x] F4 · Listado del baúl con su estado vacío
- [x] Datos de ejemplo, sembrados bajo `-seedSampleData`

**Hito 2 · Alta de libro** — ✅ cerrado
- [x] F2 · `TMTextField` y `TMSegmentedPicker`
- [x] F5 · Formulario de alta con su ViewModel
- [x] F5 · Selector de género en dos secciones más "Otros"
- [x] F5 · Selector de estado inicial
- [x] `add` en el repositorio y botón de añadir en el Baúl

**Hito 3 · Detalle y estado** — ✅ cerrado
- [x] F2 · `TMButton` y `TMProgressBar`
- [x] F6 · Pantalla de detalle, compartida por las tres pestañas
- [x] F6 · Barra de progreso y porcentaje de avance
- [x] F6 · Sheet que ofrece solo el siguiente estado
- [x] `update` en el repositorio y navegación desde el Baúl

**Hito 4 · Portada** — ✅ cerrado
- [x] F5 · Captura desde cámara y selección desde galería
- [x] F5 · Almacenamiento de la imagen, reducida y comprimida
- [x] F6 · Portada editable desde el detalle, en cualquier momento
- [x] `InfoPlist.xcstrings` con el texto de permiso de cámara en ambos idiomas
- [x] Cámara probada en dispositivo real: el simulador no tiene

**Hito 5 · Pulido del baúl** — ✅ cerrado
- [x] F4 · Búsqueda por título y autor
- [x] F4 · Filtro por estado
- [x] F4 · Borrado con swipe
- [x] F5 · Edición de libro, sin tocar el estado
- [x] `delete` en el repositorio

**Hito 6 · Sesión de lectura** — ✅ cerrado
- [x] F1 · `ReadingSessionEntity` y su repositorio
- [x] F7 · Listado de libros en curso
- [x] F8 · Selector de duración
- [x] F8 · Cuenta atrás con pausa y fin anticipado
- [x] F8 · Continuidad en segundo plano y notificación local
- [x] F8 · Modal de página final y actualización del avance
- [x] Notificación probada en dispositivo real: llega con la app cerrada

**Hito 7 · Seguimiento** — ✅ cerrado
- [x] F9 · Selector de rango con atajos de 7/15/30 días
- [x] F9 · Gráfica de minutos por día
- [x] F9 · Total y promedio del rango

**Continuo, en cada hito**
- [ ] Revisar la pantalla en inglés: es donde se rompen los layouts por longitud de texto
- [ ] Revisar accesibilidad y Dynamic Type
- [ ] Tests de ViewModels y repositorios

---

## Decisiones cerradas

Para no volver a discutirlas:

1. El autor se mantiene, como campo opcional.
2. Un solo género por libro, de una lista cerrada. Las etiquetas libres quedan fuera de la v1.
3. La portada admite cámara y galería.
4. El paso a *leído* es manual; la app lo propone al registrar la última página.
5. Las transiciones de estado son de un solo sentido, sin marcha atrás.
6. Se puede registrar un libro directamente como comprado, leyendo o leído.
7. Puede haber varios libros en *leyendo* a la vez.
8. El cronómetro sobrevive a salir de la app y avisa con notificación local.
9. Se puede pausar y terminar antes de tiempo; cuenta el tiempo realmente leído.
10. El número de páginas es obligatorio, y el modal de fin de sesión también.
11. La gráfica muestra minutos por día más el promedio del rango.
12. La búsqueda cubre título y autor, y actúa **dentro de la estantería abierta**
    ([C06](../cambios/C06-baul-por-estado.md)).
13. Los libros se pueden editar y borrar.
14. Al tocar un libro se abre el detalle; el cambio de estado es un sheet dentro del detalle.
15. La lista de géneros es la de arriba, cerrada y con "Otros" como salida.
16. El formulario de edición **no** toca el estado: el estado solo avanza por el sheet del
    detalle, para que la regla de un solo sentido no tenga puerta trasera.
17. Las sesiones de lectura no se pueden borrar, **ni siquiera al borrar su libro**: lo que se
    mide es el tiempo invertido en leer, no qué libros se terminaron ([C01](../cambios/C01-confirmar-borrado.md)).
18. ~~El baúl se ordena por fecha de creación~~ — sustituida por la #28
    ([C06](../cambios/C06-baul-por-estado.md)).
19. El modo oscuro es el cálido de "Literary Warmth", no el neutro que traía el kit de diseño.
20. El estado se muestra como punto y texto de color, sin píldora de fondo.
21. La app se publica en español e inglés, con todos los textos localizados desde el primer
    día. Ninguna cadena visible se escribe a mano en el código.
22. **Borrar un libro pide confirmación**, con una alerta que lo nombra. Sustituye a la regla
    del [Hito 5](hito-5-pulido-baul.md), que no la pedía ([C01](../cambios/C01-confirmar-borrado.md)).
23. **Solo puede haber una sesión de lectura a la vez**, y sobrevive a cerrar la app. Se retoma
    desde un aviso sobre la barra de pestañas ([C02](../cambios/C02-retomar-sesion.md)).
24. Una sesión que venció hace más de 24 horas se descarta sola: preguntar por su página ya no
    tendría respuesta útil ([C02](../cambios/C02-retomar-sesion.md)).
25. Existe una cuarta pestaña, **Perfil**, para lo que actúa sobre la biblioteca entera. Se
    llama así porque ahí vivirá el inicio de sesión ([C05](../cambios/C05-perfil-importar-exportar.md)).
26. **Importar añade, nunca reemplaza**, y un libro con errores se omite sin detener el resto
    del archivo ([C05](../cambios/C05-perfil-importar-exportar.md)).
27. **Una exportación cubre libros, no portadas ni sesiones de lectura.** No es una copia de
    seguridad completa, y la pantalla lo dice ([C05](../cambios/C05-perfil-importar-exportar.md)).
28. **El baúl muestra una estantería a la vez**, elegida con chips y sin opción de verlas todas.
    Dentro de cada una manda la fecha de la última llegada, no la de registro: lo que acabas de
    mover encabeza la lista ([C06](../cambios/C06-baul-por-estado.md)).
29. **La estantería elegida se recuerda**, y al guardar un libro el baúl salta a la suya: guardar
    algo que no puedes ver parece que no hizo nada ([C06](../cambios/C06-baul-por-estado.md)).
30. **Cada sesión guarda la página en la que empezó**, además de la final. Es lo que permite
    contar páginas leídas sin deducirlas encadenando sesiones, que falla en un libro importado
    con progreso ya hecho ([C08](../cambios/C08-historial-de-sesiones.md)).
31. **El seguimiento lista las sesiones bajo la gráfica**, cinco de entrada y cinco más por cada
    "ver más", dentro del rango elegido. Las sesiones de libros borrados no salen en la lista
    aunque sigan contando en la gráfica: una fila sin nombre no informa de nada
    ([C08](../cambios/C08-historial-de-sesiones.md)).
32. **Con un solo libro en curso, la sesión se empieza desde la pestaña**, sin entrar al libro:
    con uno no hay nada que elegir. Con dos o más el botón desaparece y hay que entrar, porque
    ahí la elección sí decide algo ([C09](../cambios/C09-iniciar-sesion-desde-en-curso.md)).
33. **El tema se elige en Configuración**, dentro del perfil: automático —que es lo predeterminado
    y sigue al teléfono—, claro u oscuro. Se recuerda entre arranques
    ([C11](../cambios/C11-tema-configurable.md)).

Los cambios posteriores a la v1 viven en [`../cambios/README.md`](../cambios/README.md).
