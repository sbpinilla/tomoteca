# C03 · Campos más cómodos de enfocar

**Tipo:** Mejora · **Estado:** ✅ Cerrado

Tocar en cualquier punto de la fila enfoca su campo, y la fila es lo bastante alta para acertar
sin apuntar. El aspecto no cambia.

## Por qué

Enfocar un campo del formulario cuesta más de lo que debería. `TMTextField` dibuja la etiqueta
encima y el campo debajo, y **lo único que responde al toque es la línea de texto**, de unos 20
puntos de alto. El resto de la fila — la etiqueta, el espacio a los lados, el hueco entre ambos —
no hace nada. Hay que apuntar al renglón.

Apple recomienda 44 puntos como mínimo para cualquier zona tocable. La línea de texto se queda
en menos de la mitad.

## Alcance

**Entra**

- Toda la fila de `TMTextField` responde al toque y pone el foco en su campo
- La fila alcanza los 44 puntos de alto como mínimo

**No entra**

Cualquier cambio de aspecto. Ni contorno, ni caja, ni etiqueta flotante: la fila se ve
exactamente igual que hoy, solo que responde donde antes no lo hacía.

## Decisiones

- **Se descarta el campo con contorno estilo Material** que se planteó primero. Resolvía la
  puntería, pero a cambio de importar un patrón de otra plataforma, rehacer la maquetación del
  formulario y arrastrar un problema con los tamaños de accesibilidad. El problema era el área
  tocable, y eso se arregla solo.
- **El foco se lleva con `@FocusState` dentro del propio componente.** Nadie de fuera tiene que
  enterarse: quien use `TMTextField` no cambia una línea.
- **La zona tocable es el rectángulo entero**, incluidos los huecos vacíos, no solo lo que tiene
  algo dibujado encima.
- **La altura mínima se consigue con relleno vertical**, no con una altura fija, para que el
  campo siga creciendo con el tamaño de letra en vez de recortarlo.
- **No se añade señal visual de foco.** Hoy no la hay, y añadirla es un cambio de aspecto: si
  hace falta, es otro cambio y se decide mirándolo.

## Criterios de aceptación

- [x] Tocar la etiqueta enfoca el campo
- [x] Tocar el espacio vacío junto a la etiqueta enfoca el campo
- [x] La fila mide 44 puntos o más
- [x] La pantalla conserva su estilo en los dos modos — las filas son algo más altas, que es
      precisamente el cambio
- [x] Con tamaños de letra grandes el campo crece en vez de recortarse
- [x] VoiceOver sigue anunciando el nombre del campo
- [x] Los tests de UI que escriben en el formulario siguen encontrando los campos

## Impacto en lo ya escrito

Solo `TMTextField`. Su interfaz no cambia, así que `BookFormView` y sus tests deberían quedarse
como están; si algún test de UI tocaba coordenadas en lugar del campo, habrá que ajustarlo.

## Cómo se validó

**Dos tests de UI nuevos**, y antes de darlos por buenos se comprobó que **fallan sin el
cambio**: uno toca la etiqueta del campo y escribe; el otro toca el hueco vacío a la derecha de
la etiqueta. Ambos fallan al quitar `contentShape` y `onTapGesture`, y pasan al devolverlos.

**Los tests de UI existentes no necesitaron ningún ajuste.** El riesgo era que el
`onTapGesture` del contenedor interceptase el toque antes de llegar al `TextField`, dejando sin
efecto los `app.textFields[...].tap()` que ya había. No ocurre.

**En simulador:** el formulario en claro y oscuro conserva su estilo, y con el mayor tamaño de
accesibilidad los campos crecen y la pantalla hace scroll, sin recortes.

## Hallazgos

- **El segundo test nació sin probar nada.** Tocaba dentro del propio `TextField`, que ya ocupaba
  el ancho de la fila antes del cambio, así que habría pasado igual sin él. Se reancló a la
  etiqueta, apuntando al hueco que antes se tragaba los toques. Un test que no falla sin el
  cambio no lo está probando.
- **Los 44 puntos van como constante privada del componente**, no como paso de `Spacing`. Es un
  mínimo de plataforma, no una elección de diseño, y meterlo en la escala lo convertiría en un
  espaciado más que alguien podría usar como margen.
