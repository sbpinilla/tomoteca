# Hito 3 · Detalle y estado

**Estado:** ✅ Cerrado

La ficha del libro, con su avance, y el único sitio desde el que el estado avanza.

## Alcance

**Entra**

- `TMButton` y `TMProgressBar`
- La pantalla de detalle: portada, título, autor, género, estado y avance
- El sheet de cambio de estado, con su stepper y su botón
- `update` en el repositorio
- La navegación desde la fila del Baúl hasta el detalle

**No entra**

- **Editar**, que llega en el Hito 5 reutilizando el formulario del Hito 2
- **Iniciar sesión de lectura**, que llega en el Hito 6. El botón no se dibuja hasta que hace
  algo, igual que se omitió el recuadro de portada en el formulario
- La portada real, todavía un marcador de posición hasta el Hito 4

## Decisiones

- **El sheet ofrece un solo botón, el del siguiente estado.** El stepper que lo acompaña es
  informativo: muestra dónde está el libro dentro del ciclo, pero no se puede tocar. Ofrecer los
  cuatro estados invitaría a intentar retroceder, que es justo lo que la regla prohíbe.
- **En un libro terminado no hay botón**, solo el stepper completo y la nota de que los estados
  no se revierten.
- **El detalle se suscribe al repositorio en vez de recibir un libro fijo**, para que al cambiar
  el estado la pantalla se actualice sola en lugar de quedarse con una copia vieja.
- **El texto de página usa un formato posicional del catálogo**, no una frase montada en Swift:
  "Página 210 de 340" y "Page 210 of 340" no llevan los números en el mismo sitio en todos los
  idiomas.
- **El botón nombra su destino** — "Marcar como leído" —, no la acción genérica "Cambiar", para
  que se lea qué va a pasar antes de pulsarlo.

## Criterios de aceptación

- [x] Tocar una fila del Baúl abre el detalle de ese libro
- [x] El detalle muestra título, autor, género, estado, barra de avance y página
- [x] El sheet ofrece únicamente el siguiente estado
- [x] Un libro terminado no ofrece ningún avance
- [x] Al avanzar el estado, el detalle y el Baúl se actualizan
- [x] La pantalla se ve correcta en los dos idiomas y los dos modos
- [x] Hay tests del avance de estado y de la actualización en el repositorio

## Cómo se validó

**Tests unitarios:** el ciclo completo paso a paso, que un libro terminado no se mueve ni se
reabre, que avanzar conserva todo lo demás del libro, que el sheet se cierra al avanzar y se
queda abierto si la escritura falla, y que el detalle recoge un cambio hecho en otro sitio.
En el repositorio, que `update` sobreescribe en lugar de duplicar y que actualizar un libro
inexistente da error en vez de crearlo.

**Tests de UI:** abrir un libro desde el Baúl, avanzar su estado y comprobar que el cambio se
ve tanto en el detalle como en la fila de la lista al volver, y que un libro terminado no
ofrece ningún botón de avance.

**Visualmente:** capturas tomadas desde el propio test de UI y extraídas del bundle de
resultados, para revisar el detalle y el sheet por ojo y no solo por aserción.

## Hallazgos

- **El botón de estado se anuncia como "Estado, Comprado"**, que es lo correcto para VoiceOver
  pero no algo sobre lo que un test pueda buscar. Se le puso un identificador de accesibilidad,
  que no cambia cuando cambia la etiqueta.
- **Los dobles de prueba se estaban multiplicando.** Cada método nuevo del protocolo rompía tres
  clases falsas distintas, una por archivo de test. Se unificaron en un único
  `FakeBookRepository` en `tomotecaTests/Support/`: ahora el protocolo solo rompe un tipo.
- Se añadió `RepositoryError.bookNotFound`, para el caso de actualizar un libro que otro sitio
  ya borró. Hoy no puede pasar, pero el borrado llega en el Hito 5.
