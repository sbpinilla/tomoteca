# C02 · Retomar una sesión interrumpida

**Tipo:** Corrección · **Estado:** ✅ Cerrado

Una sesión de lectura sobrevive a cerrar la app, y se puede retomar al volver.

## El fallo

El estado de la sesión vive **solo en memoria**. Al matar la app se pierde entero, pero la
notificación ya está programada en el sistema y sigue su curso. El resultado es el que describe
Sergio: vuelves, arrancas otra sesión, y a media sesión nueva llega el aviso de la anterior.

Analizándolo aparece un segundo agujero, que no hace falta matar la app para provocar: **nada
impide tener dos sesiones a la vez.** Basta abrir el detalle de otro libro y empezar otra; la
segunda pisa la notificación de la primera, y la primera queda contando sin que nadie la mire.

## Alcance

**Entra**

- Guardar la sesión en curso fuera de memoria, y recuperarla al arrancar
- Un aviso sobre la barra de pestañas cuando hay una sesión viva
- Impedir que haya más de una sesión a la vez
- Cerrar una sesión vencida mientras la app estaba cerrada
- Descartar sesiones demasiado viejas

**No entra**

Sesiones de varios libros a la vez, y pausar desde el aviso sin entrar.

## Cómo funciona

Al empezar, la sesión se guarda: qué libro, cuántos minutos se pidieron, cuándo empezó, cuánto
lleva acumulado y desde cuándo corre el tramo actual. Se actualiza al pausar y al reanudar, y se
borra al cerrarla. **El tiempo se sigue calculando restando fechas**, así que lo guardado basta
para reconstruir la cuenta atrás exacta sin haber estado ejecutándose.

Al abrir la app:

| Situación | Qué pasa |
|---|---|
| No hay sesión guardada | Nada, como hasta ahora |
| La sesión sigue corriendo | Aparece el aviso con el tiempo restante |
| El tiempo se cumplió estando cerrada | Aparece el aviso, dándola por completada |
| El tiempo se cumplió hace más de 24 h | Se descarta en silencio y se cancela su notificación |

Tocar el aviso entra en la sesión:

- **Si sigue corriendo**, se abre el cronómetro y ya está. **No se pide la página**: eso solo
  ocurre cuando la sesión termina.
- **Si estaba vencida**, se abre directamente el modal de página, con el tiempo planificado
  completo como tiempo leído.

## Decisiones

- **El aviso no se abre solo.** Aparece encima de la barra de pestañas y espera. Abrir una
  pantalla completa al arrancar sería atropellar a quien solo quería mirar el baúl.
- **El aviso va dentro de cada pestaña, no sobre la `TabView`.** Puesto en la `TabView`, el
  hueco que reserva cae atravesando la barra de pestañas y la tapa. Dentro de una pestaña, el
  aviso termina donde empieza la barra: encima de ella, no sobre ella.
- **Una sesión vencida cuenta el tiempo planificado completo.** Si arrancaste quince minutos y
  el aviso ya sonó, esos quince minutos ocurrieron; descartarlos perdería lectura real.
- **Una sola sesión a la vez.** Con una viva, el botón de iniciar de cualquier libro lleva a
  retomarla en lugar de abrir otra.
- **Se descartan las sesiones vencidas hace más de 24 horas.** Preguntar por la página de una
  sesión de la semana pasada no tiene respuesta útil, y el aviso se volvería permanente.
- **Se guarda en `UserDefaults`, no en Core Data.** Es un único registro efímero que se borra en
  cuanto la sesión se cierra; no es historial, y meterlo en el almacén obligaría a distinguir
  sesiones de verdad de sesiones a medias.

## Criterios de aceptación

- [x] Matar la app durante una sesión y volver muestra el aviso con el tiempo correcto
- [x] Tocar el aviso con la sesión viva abre el cronómetro, sin pedir página
- [x] El tiempo transcurrido con la app cerrada cuenta
- [x] Volver después de vencido el tiempo lleva al modal de página, con el tiempo completo
- [x] Con una sesión viva no se puede arrancar otra
- [x] Cerrar la sesión borra el estado guardado y el aviso desaparece
- [x] Una sesión vencida hace más de 24 h se descarta sin dejar aviso ni notificación
- [x] Hay tests de guardar, recuperar, vencer y descartar

## Cómo se validó

**Tests unitarios con reloj de mentira:** que arrancar guarda la sesión; que arrancar una
segunda con otra sesión viva no la reemplaza sino que trae la primera al frente; que una sesión
guardada se recupera con el tiempo ya transcurrido y **sin** abrirse sola; que una vencida vuelve
pidiendo la página; que una vencida hace más de 24 h se descarta junto con su notificación; que
una a punto de cumplir el plazo todavía se ofrece; que una pausada nunca caduca; y que cerrarla
limpia lo guardado. En el ViewModel: que pausar y reanudar se escriben, que retomar conserva el
tiempo corrido, que una sesión vencida registra el tiempo planificado y no las horas
transcurridas desde entonces, y que mientras pide la página el estado sigue guardado.

**Test de UI que mata la app de verdad**, que es lo único capaz de probar esto: arranca una
sesión, llama a `terminate()`, relanza, comprueba que el aviso está ahí con la cuenta atrás
continuada, entra y verifica que **no** pide la página. Un segundo test abre otro libro tras el
relanzamiento y comprueba que ofrece retomar en vez de empezar otra. Usa el almacén real: uno
en memoria muere con el proceso, que es justo lo que se está probando.

## Hallazgos

- **El ViewModel se estaba creando en cada render.** Al construirlo dentro del `fullScreenCover`
  se rehacía cada vez que algo cambiaba en pantalla, tirando la fase y lo tecleado en la página.
  Ahora lo retiene el controlador y se construye una sola vez.
- **Presentar la sesión desde el callback de la hoja de duración no funcionaba.** SwiftUI
  descarta la segunda presentación cuando llega mientras la primera se está cerrando: la hoja se
  cerraba y detrás no aparecía nada. Se encadena con `onDismiss`.
- **Colocar el aviso en la `TabView` lo dejaba encima de la barra de pestañas, tapándola.**
  Movido al contenido de cada pestaña, queda justo por encima. Comprobado en captura.
- **El aviso se anuncia entero para VoiceOver** — "Retomar sesión, Cien años de soledad, 09:53" —,
  lo que hizo fallar un test que buscaba el título del libro sin acotar a la lista. El test
  estaba mal; el anuncio está bien.
