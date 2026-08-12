# Hito 4 · Portada

**Estado:** ✅ Cerrado

Añadir la portada de un libro desde la cámara o la galería, **en cualquier momento de su vida**,
no solo al darlo de alta.

## Alcance

**Entra**

- `TMBookCover`, que dibuja la portada o su marcador de posición
- Captura desde cámara y selección desde galería
- El recuadro de portada en el formulario de alta, opcional
- La portada del detalle, tocable para añadirla, cambiarla o quitarla
- Reducción y compresión de la imagen antes de guardarla
- Textos de permiso, localizados

**No entra**

Recortar o encuadrar la imagen. Se guarda tal cual llega, reducida.

## Decisiones

- **La portada se puede añadir en cualquier momento, no solo en el alta.** Al registrar un libro
  que aún se quiere comprar casi nunca se tiene la foto a mano; se tiene después, cuando ya está
  en la estantería. Obligar a pasar por la edición completa para eso sería un rodeo.
- **Por eso el punto de entrada principal es el detalle**, tocando la portada. El formulario
  también la ofrece, pero como atajo, no como el único momento posible.
- **La imagen se reduce a 1200 px de lado mayor y se guarda en JPEG.** Una foto de cámara ronda
  varios megabytes; guardarla íntegra en la base de datos hincharía el almacén y ralentizaría
  cada lectura del catálogo, para mostrarla luego en un recuadro de 44 puntos.
- **Se usa `PhotosPicker` para la galería**, que corre fuera del proceso y por tanto no necesita
  permiso ni pide nada al usuario. La cámara sí necesita permiso, y ese sí lleva su texto.
- **El menú de origen es un `confirmationDialog`**, no una pantalla propia: son tres opciones y
  no merecen navegación.
- **La cámara no aparece cuando no hay ninguna**, que es el caso del simulador.

## Criterios de aceptación

- [x] El formulario permite añadir portada, y guardar sigue funcionando sin ella
- [x] El detalle permite añadir, cambiar y quitar la portada
- [x] La portada se ve en la fila del Baúl y en el detalle
- [x] Un libro sin portada muestra el marcador de posición
- [x] La imagen guardada está reducida, no en su tamaño original
- [x] El texto de permiso de cámara está en los dos idiomas
- [x] Hay tests del procesado de imagen y de asignar y quitar portada

## Cómo se validó

**Tests unitarios:** que una foto grande se reduce al límite, que conserva las proporciones,
que una imagen pequeña no se agranda, que lo guardado pesa menos de la cuarta parte del
original, y que el límite se mide en píxeles aunque la imagen traiga factor de escala. En el
ViewModel, añadir, reemplazar y quitar portada, y hacerlo después de avanzar el estado.

**En simulador:** el Baúl con portadas reales en dos libros y marcador de posición en los otros
dos, y el formulario con "Agregar portada · cámara o galería".

**Sin validar:** la captura desde cámara. El simulador no tiene una, así que ese camino solo
está comprobado por lectura de código. Hay que probarlo en un dispositivo real antes de dar la
portada por terminada.

## Hallazgos

- **Un fallo real de puntos contra píxeles.** El límite de tamaño se comparaba con `size`, que
  va en puntos, mientras que el límite es de píxeles. Una imagen con factor de escala 3 tiene
  nueve veces más píxeles de los que su `size` sugiere, así que habría pasado el filtro y se
  habría guardado a resolución completa. Lo destapó el test de que una imagen pequeña no se
  agranda, que fallaba por el mismo motivo.
- **El sembrado de datos duplicaba el mapeo a entidades** y por eso se quedó sin portadas en
  cuanto se añadió el campo. Ahora siembra a través del repositorio, que es donde vive esa
  conversión; una segunda copia se desincroniza a la primera columna nueva.
- **La galería no necesita permiso.** `PhotosPicker` corre fuera del proceso, así que no hay
  prompt ni texto de uso que escribir. Solo la cámara lo lleva.
