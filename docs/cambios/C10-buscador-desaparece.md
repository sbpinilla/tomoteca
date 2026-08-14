# C10 · El buscador del baúl desaparecía al volver de un libro

**Tipo:** Corrección · **Estado:** ✅ Cerrado

Entrar a un libro y volver dejaba el baúl sin campo de búsqueda.

## El fallo

En el baúl, tocar un libro y volver atrás: el campo de búsqueda ya no está. No está oculto
esperando a que se tire de la lista hacia abajo — no está. La única forma de recuperarlo es
cambiar de pestaña y volver.

### Por qué

`.searchable` se dejó con la colocación por defecto, que es
`.navigationBarDrawer(displayMode: .automatic)`. Ese "automático" permite que el campo se pliegue
dentro de la barra de navegación cuando la lista se desplaza. Al apilar el detalle y volver, el
`NavigationStack` rehace su barra con el campo plegado — y ya no vuelve a desplegarse. No queda
oculto esperando un tirón hacia abajo: **desaparece del árbol de la pantalla entero**, que es lo
que confirmó volcar la jerarquía de accesibilidad en el fallo.

Fijarlo con `displayMode: .always` lo quita de esa decisión: el campo está siempre.

### Lo que primero pareció la causa, y no lo era

`.searchable` cuelga del `NavigationStack`, no de lo que el `NavigationStack` contiene. Eso salta
a la vista al leer el archivo, encaja con el síntoma —un campo que no pertenece a ninguna pantalla
de la pila y por eso no vuelve con ella— y es lo que se escribió aquí como diagnóstico antes de
comprobarlo.

Moverlo dentro no arregló nada: el test siguió fallando igual. Y con `.always` puesto, funciona
tanto dentro como fuera. La colocación no tenía que ver, así que se queda donde estaba: el arreglo
es una línea, no dos.

## Alcance

**Entra**

- Que el campo siga ahí al volver de un libro
- Un test que lo compruebe

**No entra**

Cambiar la búsqueda, los chips o el detalle.

## Decisiones

- **El campo se fija con `.always`.** Es la línea que arregla el fallo, y de paso el buscador deja
  de esconderse al desplazar la lista: en una pantalla cuya razón de ser es encontrar un libro
  entre muchos, que el buscador se vaya solo nunca ayudó.
- **No se toca la colocación.** Parecía culpable y no lo era; cambiarla de paso habría dejado en
  el commit una línea que nadie puede justificar con un test.

## Criterios de aceptación

- [x] Volver de un libro deja el campo de búsqueda en su sitio
- [x] Y buscando: se escribe en él y la lista se filtra
- [x] Buscar algo que no existe sigue sin llevarse el campo (lo del C06)
- [x] Hay un test que falla con el código anterior

## Cómo se validó

**Dos tests de UI escritos antes que el arreglo**, y ejecutados antes de tocar nada para verlos
fallar: `testTheSearchFieldSurvivesAVisitToABook` entra a un libro, vuelve y comprueba que el
campo sigue ahí; `testSearchingAfterComingBackFromABook` además escribe en él y comprueba que la
lista se filtra, porque un campo presente pero muerto también sería un fallo.

Los dos fallaban de forma determinista antes del cambio y pasan después. Con el fallo delante, el
volcado de `app.debugDescription` fue lo que dio el diagnóstico bueno: en el árbol no había
`SearchField` de ninguna clase — ni oculto ni plegado — y sí quedaba el `AdditionalDimmingOverlay`
que el sistema pone tras la búsqueda.

El resto de `TrunkFlowUITests` se corrió entero: buscar, buscar sin resultados, chips, borrar y
editar siguen pasando, que es lo que confirma que fijar el campo no rompió el arreglo del C06.

Suite completa: 166 tests unitarios y 31 de UI, todos en verde.

## Hallazgos

- **El diagnóstico evidente era el falso.** `.searchable` colgado del `NavigationStack` explicaba
  el síntoma de principio a fin, y estaba escrito en este documento como la causa. Moverlo dentro
  no cambió nada, y con `.always` funciona en los dos sitios. Se quedó donde estaba.
- **Escribir el test antes del arreglo es lo que lo cazó.** Con el orden de siempre —arreglar y
  luego probar— el test habría pasado a la primera y la línea equivocada se habría quedado en el
  commit disfrazada de arreglo.
- **`app.debugDescription` en el mensaje de un `XCTAssert` es la forma barata de ver la pantalla**
  en un fallo de UI: el árbol entero, sin recompilar nada ni exportar el bundle de resultados.
