# C07 · El cronómetro de la sesión se quedaba congelado

**Tipo:** Corrección · **Estado:** ✅ Cerrado

La cuenta atrás de la sesión de lectura se quedaba fija en el tiempo inicial y no avanzaba.

## El fallo

Al entrar en una sesión, el cronómetro muestra `10:00` y ahí se queda: el número no baja, el
anillo de progreso no se mueve, y no hay forma de ver cuánto llevas leído.

El tiempo interno sí corre — está calculado restando fechas, no acumulando ticks —, así que al
vencer el plazo la notificación llega y la sesión se cierra bien. Lo que no ocurre es el
**redibujado**: nadie le pide a la pantalla que vuelva a leer el reloj.

### Por qué

`ActiveSessionView` se redibuja con un `Timer.publish(every: 1)` declarado como propiedad de la
vista y consumido con `onReceive`. Cada vez que SwiftUI reconstruye el struct de la vista se crea
un publicador **nuevo**, y `onReceive` cancela la suscripción anterior y se suscribe al nuevo, lo
que reinicia la ventana de un segundo desde cero.

Y algo lo reconstruye exactamente una vez por segundo: `RootTabView` tenía su propio timer de un
segundo llamando a `sessionController.objectWillChange.send()` para refrescar el aviso de sesión
activa. Ese aviso obligaba a reevaluar el `body` de la raíz entera, incluido el contenido del
`fullScreenCover` donde vive la sesión.

Los dos timers corren al mismo intervalo, así que quien gane la primera vez gana siempre: si el
de la raíz llega antes, reinicia al de la sesión indefinidamente y el cronómetro se queda clavado
en el tiempo inicial. Si gana el otro, todo funciona. **Es una carrera**, y de ahí que se vea a
veces sí y a veces no.

El fallo es la conjunción de dos cosas, y las dos están mal por separado:

1. Un publicador recreado en cada actualización de la vista nunca es estable.
2. Un tick en la raíz que invalida la app entera una vez por segundo para animar un aviso de
   cuatro palabras.

## Alcance

**Entra**

- Que la cuenta atrás y el anillo avancen mientras la sesión corre
- Sacar el tick de un segundo de la raíz y dejarlo donde se necesita
- Un test que compruebe que el número **cambia**, no solo que existe

**No entra**

Cambiar el diseño de la pantalla de sesión, ni cómo se calcula el tiempo: eso ya era correcto.

## Decisiones

- **El publicador del timer vive en `@State`.** Es lo que le da identidad estable entre
  actualizaciones: se crea una vez y la suscripción sobrevive a que la vista se reconstruya.
- **Cada quien se refresca a sí mismo.** El aviso de sesión activa lleva su propio tick, en una
  vista pequeña que solo lo contiene a él. La raíz deja de tener timer, y una sesión en curso deja
  de repintar las cuatro pestañas cada segundo.
- **El aviso sigue leyendo la hora del controlador en cada pintada.** El tick solo provoca el
  redibujado; el tiempo mostrado se sigue derivando del reloj, igual que antes. Guardarlo en
  estado abriría la puerta a mostrar un valor viejo.

## Criterios de aceptación

- [x] La cuenta atrás baja segundo a segundo mientras la sesión corre
- [x] El anillo de progreso avanza con ella
- [x] Pausar detiene el número; reanudar lo vuelve a mover
- [x] El tiempo restante del aviso de sesión activa sigue actualizándose
- [x] Al cumplirse el plazo se sigue pidiendo la página
- [x] Hay un test que falla con el código anterior

## Cómo se validó

**Un test de UI que lee el cronómetro dos veces**, `testTheCountdownRunsDownOnScreen`: arranca una
sesión de diez minutos, guarda la etiqueta, sondea hasta seis segundos a que cambie, y comprueba
que cambió y que fue hacia abajo. Es lo único que cazaba esto: el fallo está en el ciclo de
actualización de SwiftUI, no en el ViewModel, así que las pruebas unitarias del tiempo lo daban
por bueno, y los tests de UI que ya existían — que solo miraban que la etiqueta existiera y
cayera en un rango — pasaban con el fallo delante.

Un segundo test cubre pausar y reanudar: que el número se queda quieto mientras está en pausa, y
que vuelve a moverse al reanudar.

**Verificado contra el código anterior, y ahí está lo interesante:** la primera pasada sin el
arreglo **pasó**. Repetida, falló a la tercera con `("10:00") is equal to ("10:00")`, que es
exactamente lo que se ve en pantalla. Una de cada cuatro ejecuciones en el simulador; en el
teléfono de Sergio salía casi siempre. Con el arreglo, seis de seis. Eso confirmó que era una
carrera y no un fallo determinista, que es lo que explica que el bug pareciera intermitente.

Suite completa: 144 tests unitarios y 23 de UI, todos en verde.

No hay cambio visual: las dos pantallas afectadas se ven igual que antes, y lo que se arregla es
que se repinten. La captura `active-session` del test sigue siendo la misma.

## Hallazgos

- **El primer test escrito para reproducir el fallo pasó.** Ejecutarlo una sola vez habría dado
  por bueno el código anterior y por innecesario el arreglo. Repetirlo fue lo que separó "no
  ocurre" de "ocurre una de cada cuatro veces".
- **La carrera nunca fue solo del cronómetro.** Refrescar el aviso invalidando la raíz repintaba
  las cuatro pestañas una vez por segundo durante toda la sesión. El cronómetro congelado era el
  síntoma visible de eso; el coste estaba ahí desde C02.
- **Un publicador construido como propiedad de una vista no tiene identidad.** Es el mismo error
  las dos veces, en dos archivos distintos, y no da ningún aviso al compilar: el timer parece
  correcto y a veces incluso funciona.
