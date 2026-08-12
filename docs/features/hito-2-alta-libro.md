# Hito 2 · Alta de libro

**Estado:** ✅ Cerrado

Cerrar el ciclo completo de escritura y lectura: dar de alta un libro desde un formulario y
verlo aparecer en el Baúl. Es la prueba real de que la arquitectura funciona de punta a punta.

## Alcance

**Entra**

- `TMTextField` y `TMSegmentedPicker`
- El formulario de alta con su ViewModel y su validación
- El selector de género, en dos secciones más "Otros"
- El selector de estado inicial
- `add` en el repositorio, con su implementación sobre Core Data
- El botón de añadir en la barra del Baúl

**No entra**

La portada, que llega en el Hito 4. El formulario no muestra el recuadro de "Agregar portada"
del mockup: un control muerto confunde más de lo que promete.

La edición de un libro existente, que llega en el Hito 5 reutilizando este mismo formulario.

## Decisiones

- **`TMButton` no se construye todavía.** El formulario usa los botones nativos de la barra de
  navegación; el primer botón propio aparece en el detalle, con "Iniciar sesión de lectura".
- **El estado inicial usa etiquetas cortas.** En el segmentado no caben cuatro etiquetas largas,
  así que "Quiero comprar" se muestra como "Comprar". Son cadenas aparte de las del listado,
  no un recorte en tiempo de ejecución.
- **El género arranca sin seleccionar.** Es obligatorio, y preseleccionar uno haría que el libro
  se archivara mal por omisión.
- **Guardar permanece deshabilitado hasta que el formulario es válido**, en vez de dejar
  pulsarlo y mostrar un error después.
- **El número de páginas se teclea, no se ajusta con un stepper**: son cientos, y el teclado
  numérico es más rápido.
- El mockup no muestra el botón de guardar. Se añade a la derecha de la barra, que es donde
  lo espera cualquier usuario de iOS.

## Criterios de aceptación

- [x] El botón de añadir abre el formulario desde el Baúl
- [x] Guardar está deshabilitado hasta que hay título, género y páginas válidas
- [x] Al guardar, el libro aparece en el Baúl sin recargar la pantalla
- [x] El género se elige de una lista en dos secciones más "Otros"
- [x] El estado inicial se puede fijar en cualquiera de los cuatro
- [x] Cancelar descarta lo escrito
- [x] La pantalla se ve correcta en los dos idiomas y los dos modos
- [x] Hay tests de la validación y del guardado

## Cómo se validó

**Tests unitarios:** validación del formulario, recorte de espacios, autor en blanco guardado
como ausente, rechazo de páginas no numéricas, y `add` en el repositorio comprobando que el
libro sobrevive a releer el almacén con un repositorio nuevo.

**Test de UI, que es el que de verdad cierra el hito:** abre el formulario, comprueba que
Guardar está deshabilitado, escribe el título, elige género, escribe las páginas, comprueba que
Guardar se habilita, guarda, y verifica que el libro aparece en el Baúl y el estado vacío
desaparece. Un segundo test comprueba que Cancelar descarta lo escrito.

**En simulador:** formulario en español claro e inglés oscuro.

## Hallazgos

- **Un fallo de accesibilidad en `TMTextField`.** Como la etiqueta se dibuja encima del campo,
  el `TextField` quedaba sin nombre y VoiceOver habría anunciado un campo mudo. Se le añadió
  `accessibilityLabel`, que además es lo que permite al test de UI encontrarlo.
- **Los tests de UI se contaminaban entre sí.** Comparten el almacén real, así que el libro que
  añadía el primero seguía ahí cuando el segundo esperaba un baúl vacío. Se añadió
  `-useInMemoryStore`: en depuración, `PersistenceController.shared` usa un almacén desechable.
- **Se quitó el `assertionFailure` del guardado.** Un fallo al escribir es una condición real de
  ejecución — disco lleno, almacén bloqueado —, no un error de programación, y hacer caer las
  compilaciones de depuración por eso no ayuda a nadie. Queda pendiente mostrarle el fallo al
  lector, que hoy solo mantiene la hoja abierta.
- El mockup no tenía botón de guardar. Se añadió a la derecha de la barra.
