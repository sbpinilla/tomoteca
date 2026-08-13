# C04 · Tests más rápidos de ejecutar

**Tipo:** Mejora · **Estado:** ✅ Cerrado

Quitar de la suite lo que no prueba nada, y dejar escrito cómo ejecutarla sin recompilar ni
correrla entera en cada iteración.

## Por qué

Validar un cambio de un solo archivo cuesta cinco minutos. Medido: la suite completa tarda
**295 segundos**.

Los tests unitarios no son el problema — los noventa y pico corren en menos de un segundo. Todo
el tiempo se va en los de UI, donde cada test arranca la app desde cero, y en recompilar los tres
targets antes de cada ejecución.

Quedaban además tres tests de la plantilla de Xcode que nunca se retiraron y no prueban nada de
Tomoteca: `testLaunchPerformance`, que mide el arranque cinco veces; `testLaunch`, que se ejecuta
una vez por configuración de la app; y `testExample`, que arranca la app y no comprueba nada.
Suman unos 50 segundos de tiempo de ejecución.

Y la suite se estaba ejecutando entera después de cada cambio, incluso cuando el afectado era un
solo componente.

## Alcance

**Entra**

- Borrar los tres tests de plantilla
- Documentar en `CLAUDE.md` cómo ejecutar solo lo afectado y cómo evitar recompilar

**No entra**

Reducir los arranques de app dentro de los tests de recuperación de sesión, y mover cobertura de
UI a unitaria. Ambas cosas tocan tests que hoy prueban algo, y merecen mirarse una a una.

## Decisiones

- **Se borran, no se desactivan.** Un test deshabilitado es ruido que alguien acabará
  reactivando por si acaso.
- **Medir el arranque no es una prueba.** `testLaunchPerformance` no afirma nada: no falla
  aunque la app tarde el doble. Si alguna vez importa el tiempo de arranque, se pone un umbral
  y se justifica; hasta entonces son 29 segundos por nada.
- **La captura de `testLaunch` tampoco se conserva.** Las capturas que sirven se toman en los
  tests de flujo, en el momento que interesa, no en la pantalla inicial.
- **El atajo de ejecución se documenta, no se automatiza.** Un script escondería qué se está
  ejecutando, y lo que hace falta es elegirlo a conciencia en cada iteración.

## Criterios de aceptación

- [x] No queda ningún test de la plantilla de Xcode
- [x] Todo lo que quedaba pasando sigue pasando
- [x] `CLAUDE.md` explica cómo ejecutar un subconjunto y cómo reejecutar sin recompilar
- [ ] ~~La suite completa tarda menos que los 295 s medidos~~ — **no se cumplió**, ver abajo

## Nota sobre el flujo de dos fases

Este cambio es íntegramente sobre los tests, así que la separación entre implementación y tests
no aplica: no hay código de producción que asentar antes.

## Cómo se validó

Midiendo, que es lo que desmontó la premisa. Todos los tiempos con el simulador ya arrancado:

| Qué se ejecuta | Tiempo |
|---|---|
| Suite completa, antes de borrar los tests de plantilla | 295 s |
| Suite completa, después | 299 s |
| Solo los unitarios | 39 s |
| Solo los unitarios, sin recompilar | **27 s** |
| Una clase de tests de UI, sin recompilar | 100 s |

La suite entera sigue pasando.

## Hallazgos

- **Borrar los tests de plantilla no aceleró nada.** 295 s antes, 299 s después: dentro del
  ruido. La razón es que Xcode reparte las clases de tests de UI entre clones del simulador y
  las ejecuta en paralelo, así que quitar 50 segundos de *tiempo de test* no quita 50 segundos
  de *tiempo de reloj* — el camino crítico lo marca la clase más lenta, no la suma. La
  estimación previa de "~45 s por ejecución" era incorrecta y queda corregida aquí.
- **Se borran igual**, pero por otro motivo: `testLaunchPerformance` no puede fallar aunque la
  app tarde el doble, y `testExample` no afirma nada. Un test que no puede fallar no es un test.
- **Lo que sí funciona es no ejecutar lo que no hace falta.** El bucle habitual —cambiar código
  y comprobar los unitarios— pasa de 299 s a **27 s**, once veces más rápido, combinando
  `-only-testing` con `test-without-building`.
- **Recompilar no era el cuello de botella** que parecía: entre `test` y `test-without-building`
  hay unos 12 segundos. El coste está en los tests de UI, a 15–25 segundos cada uno porque cada
  uno arranca la app.

## Lo que se decidió no hacer

Se valoró seguir con un C05 para recortar esos 299 s reduciendo arranques de app y moviendo
cobertura de UI a unitaria. **Se descarta**, por dos razones:

- Con el bucle de 27 s, la suite completa solo se ejecuta al cerrar un cambio. Cinco minutos una
  vez no es un problema que justifique trabajo.
- Los tests de UI son lo caro y también lo que más ha encontrado: la carrera entre la hoja de
  duración y la presentación de la sesión, el ViewModel recreándose en cada render, el borrado
  apuntando al libro equivocado con un filtro activo, y el área tocable del campo. Cambiar esa
  cobertura por minutos es mal negocio.

Si algún día la espera estorba, la palanca sin coste de cobertura es subir los clones en paralelo
con `-parallel-testing-worker-count`. Es un experimento de una línea; no hace falta anticiparlo.
