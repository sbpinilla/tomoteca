# C09 · Empezar a leer sin entrar al libro

**Tipo:** Mejora · **Estado:** ✅ Cerrado

Con un solo libro en curso, el botón de iniciar sesión sale en la propia pestaña.

## Por qué

Empezar a leer son hoy tres toques: pestaña, libro, botón. Y el segundo no elige nada — casi
siempre hay un único libro en curso, así que entrar al detalle es abrir una lista de un elemento
para escoger el único que hay.

Con dos o más el paso sí decide algo, y ahí se queda como está.

## Alcance

**Entra**

- El botón de iniciar sesión en la pestaña "En curso" cuando hay exactamente un libro
- Sacar el botón, la hoja de duración y el permiso de notificaciones a un sitio compartido, para
  que las dos pantallas no tengan cada una su copia

**No entra**

Cambiar el detalle del libro, ni la pantalla con varios libros, ni elegir la duración de otra
manera.

## Cómo funciona

```
┌─────────────────────────────┐
│ ▓▓▓ Cien años de soledad    │
│ ▓▓▓ García Márquez          │
│ ▓▓▓ ▓▓▓▓▓▓▓░░░░░░  62%      │
└─────────────────────────────┘

   [ Iniciar sesión de lectura ]
```

- **Solo con un libro.** Con dos o más, el botón no aparece y la pestaña es la de siempre: hay
  que elegir, y elegir es entrar al libro.
- **La fila no cambia.** Sigue llevando al detalle, que es donde está todo lo demás del libro.
- **Hace exactamente lo mismo que el botón del detalle**, porque es el mismo botón: pide la
  duración, pide el permiso de notificaciones la primera vez, y arranca la sesión.
- **Con una sesión ya viva** dice "retomar" y la reabre, en lugar de empezar otra (#23).

## Decisiones

- **Un solo botón para las dos pantallas.** El botón arrastra la hoja de duración, la petición
  del permiso y el arranque encadenado al cierre de la hoja; copiarlo era copiar las tres cosas.
  Vive en `Features/ReadingSession/Views/`, que es de donde ya salía la hoja que usaba el detalle.
- **Con cero libros no cambia nada.** El estado vacío se queda como está: sin libro que leer no
  hay sesión que empezar.

## Criterios de aceptación

- [x] Con un libro en curso, el botón aparece bajo la fila
- [x] Toca el botón y pide la duración, igual que desde el detalle
- [x] La sesión arrancada así es indistinguible de la arrancada desde el detalle
- [x] Con dos o más libros el botón no aparece
- [x] Sin libros en curso sigue el estado vacío
- [x] Con una sesión viva el botón la retoma en vez de abrir otra
- [x] La fila sigue llevando al detalle
- [x] Se ve bien en español e inglés, en claro y en oscuro

## Cómo se validó

**En el `InProgressViewModel`**, un archivo de tests que antes no existía: que solo llegan los
libros en lectura; que `onlyBook` da el libro con uno, y nada con dos ni con ninguno; y que sigue
al catálogo en las dos direcciones — terminar uno de dos vuelve a dejar el otro a mano, y poner
un segundo a leer retira la oferta.

**En la pestaña, con tests de UI:** que el botón está y arranca la sesión hasta el cronómetro,
pasando por la misma hoja de duración que el detalle; que la fila sigue llevando al detalle y no
a la sesión; y que poner un segundo libro a leer —avanzándolo de verdad desde el baúl— retira el
botón.

Ese último empieza comprobando que el botón **está** antes de tocar nada. Sin esa primera línea
sería un test que pasa por no encontrar algo que tampoco existía antes del cambio.

**Las suites que arrancan sesiones desde el detalle se corrieron primero**, antes de escribir
nada nuevo: son las que dirían si sacar el botón a un sitio compartido rompió el camino viejo.
Pasaron sin tocarlas.

Suite completa: 166 tests unitarios y 29 de UI, todos en verde. Visto en el simulador en español
y en inglés, en claro y en oscuro.

## Hallazgos

- **Extraer el botón no costó nada, y ahí está el aviso.** Las tres cosas que arrastra —la hoja,
  el permiso y el arranque encadenado al `onDismiss`— habrían sido tres copias silenciosas si el
  botón se hubiera vuelto a escribir a mano en la pestaña. La del `onDismiss` es la que ya falló
  una vez, en el C02.
- **La pestaña pasó de `List(viewModel.books)` a `List { ForEach … }`.** El botón es una fila más,
  con fondo transparente y sin separador; el atajo corto de `List` no admite nada que no sea la
  colección.
