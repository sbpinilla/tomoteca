# Hito 7 · Seguimiento

**Estado:** ✅ Cerrado

Cuánto se lee cada día, sobre el histórico de sesiones que dejó el Hito 6.

## Alcance

**Entra**

- `TMStatTile`, la tarjeta de dato suelto
- El selector de rango: 7, 15 o 30 días
- La gráfica de barras de minutos por día
- El total del rango y el promedio diario

**No entra**

Rangos personalizados con fechas a elegir, desglose por libro, y rachas. La v1 responde a una
sola pregunta: cuánto he leído últimamente.

## Decisiones

- **Los días sin lectura se dibujan en cero, no se saltan.** Una gráfica que solo muestra los
  días con sesiones miente: siete barras seguidas parecen una semana constante aunque sean siete
  días sueltos de tres meses.
- **El rango termina hoy y cuenta hacia atrás.** "7 días" son los últimos siete incluyendo hoy,
  no la semana natural, que dejaría un lunes con una sola barra.
- **El promedio divide entre todos los días del rango, no solo entre los que tuvieron lectura.**
  Un promedio que ignora los días en blanco no es un promedio, es un consuelo.
- **Los segundos se suman antes de convertir a minutos.** Convertir cada sesión por separado y
  luego sumar pierde tres sesiones de cuarenta segundos, que son dos minutos reales.
- **El día de hoy se destaca en la gráfica** con el color de acento, para tener una referencia
  sin necesidad de leer el eje.
- **Se usa el framework `Charts`**, disponible desde iOS 16, en lugar de barras a mano: trae los
  ejes, la accesibilidad y el escalado ya resueltos.
- **El reloj se inyecta**, igual que en la sesión: sin eso, un test del rango dependería del día
  en que se ejecute.

## Criterios de aceptación

- [x] El rango se puede cambiar entre 7, 15 y 30 días
- [x] La gráfica muestra un punto por día, incluidos los días sin lectura
- [x] El total suma el tiempo real leído del rango
- [x] El promedio divide entre todos los días del rango
- [x] Sin sesiones, la pestaña lo dice en vez de mostrar una gráfica vacía
- [x] La pantalla se ve correcta en los dos idiomas y los dos modos
- [x] Hay tests del agrupado por día, del total, del promedio y de los límites del rango

## Cómo se validó

**Tests unitarios con hoy fijo y calendario UTC**, para que el rango no dependa del día ni de la
zona horaria de quien ejecute la suite: que cada rango tiene tantas entradas como días y termina
hoy; que los días vacíos se conservan en cero; que las sesiones fuera del rango se ignoran y que
un rango mayor las alcanza; que varias sesiones del mismo día se suman; que los segundos se
suman antes de convertir, comprobado con tres sesiones de cuarenta segundos que valen dos
minutos; que el promedio divide entre todos los días y baja al ampliar el rango; y que hoy es
el único día marcado.

**En simulador:** la pestaña con una semana sembrada, en español claro e inglés oscuro. El día
sin lectura aparece como hueco, y hoy destacado.

## Hallazgos

- **Las barras apagadas desaparecían en modo oscuro.** Estaban pintadas con `track`, que sobre
  la superficie oscura queda a un pelo de distancia: la gráfica se veía casi vacía. Ahora usan
  el color de acento con opacidad, que funciona en los dos modos y además coincide con el
  marrón cálido del mockup. Es el tipo de fallo que solo aparece mirando la pantalla: los tests
  pasaban igual.
- El sembrado de datos ahora incluye una semana de sesiones, sin la cual la pestaña no tenía
  nada que dibujar.
