# Features de Tomoteca

Índice de features de la v1, con el estado de cada una y el checklist general de ejecución.
Cada feature recibe su propio archivo en esta carpeta cuando se empieza a construir.

---

## Alcance de la v1

Registro personal de libros, **sin login y sin backend**: todo se guarda en local con Core Data.

Fuera de alcance por ahora: cuentas de usuario, sincronización con iCloud, escaneo de ISBN,
búsqueda en catálogos externos, préstamos, etiquetas libres, recomendaciones, notas o subrayados.

## Estructura de la app

Una `TabView` con tres pestañas:

| Pestaña | Contenido |
|---|---|
| **En curso** | Los libros en estado *leyendo*. Punto de entrada a la sesión de lectura. |
| **Seguimiento** | Gráfica de tiempo leído por día, con rango de fechas. |
| **Baúl** | El registro completo de libros: lista, búsqueda, alta, detalle. |

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

### Pendiente

**Cimientos**
- [ ] F1 · Entidades de Core Data y eliminación de `Item`
- [ ] F1 · Modelos de dominio y protocolos de repositorio
- [ ] F1 · Implementación de los repositorios sobre Core Data
- [ ] F1 · Lista precargada de géneros
- [ ] F3 · `TabView` raíz con las tres pestañas
- [ ] Reorganizar el proyecto según la estructura de `CLAUDE.md` (`App/`, `Core/`, `Features/`)

**Baúl**
- [ ] F2 · `TMEmptyState`, `TMStatusChip`, `TMCard`, `TMText`
- [ ] F4 · Listado con estado vacío
- [ ] F4 · Búsqueda por título y autor
- [ ] F4 · Filtro por estado
- [ ] F4 · Borrado con swipe
- [ ] F5 · Formulario de alta
- [ ] F5 · Captura de portada desde cámara y galería
- [ ] F5 · Edición de libro
- [ ] F6 · Pantalla de detalle
- [ ] F6 · Sheet de cambio de estado

**Lectura**
- [ ] F7 · Listado de libros en curso
- [ ] F8 · Selector de duración
- [ ] F8 · Cuenta atrás con pausa y fin anticipado
- [ ] F8 · Continuidad en segundo plano y notificación local
- [ ] F8 · Modal de página final y actualización del avance

**Seguimiento**
- [ ] F9 · Selector de rango con atajos de 7/15/30 días
- [ ] F9 · Gráfica de minutos por día
- [ ] F9 · Promedio del rango

**Transversal**
- [ ] `InfoPlist.xcstrings` con los textos de permisos en ambos idiomas
- [ ] Revisar cada pantalla en inglés: es donde se rompen los layouts por longitud de texto
- [ ] Revisión de accesibilidad y Dynamic Type
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
12. La búsqueda cubre título y autor, con filtro por estado.
13. Los libros se pueden editar y borrar.
14. Al tocar un libro se abre el detalle; el cambio de estado es un sheet dentro del detalle.
15. La lista de géneros es la de arriba, cerrada y con "Otros" como salida.
16. El formulario de edición **no** toca el estado: el estado solo avanza por el sheet del
    detalle, para que la regla de un solo sentido no tenga puerta trasera.
17. Las sesiones de lectura no se pueden borrar.
18. El baúl se ordena por fecha de creación, con los libros más recientes primero.
19. El modo oscuro es el cálido de "Literary Warmth", no el neutro que traía el kit de diseño.
20. El estado se muestra como punto y texto de color, sin píldora de fondo.
21. La app se publica en español e inglés, con todos los textos localizados desde el primer
    día. Ninguna cadena visible se escribe a mano en el código.
