# C05 · Perfil, con importar y exportar libros

**Tipo:** Feature · **Estado:** ✅ Cerrado

Una cuarta pestaña, Perfil, y dentro de ella la primera herramienta: pasar la biblioteca a un
JSON y traerla de vuelta.

## Por qué

Hay libros ya comprados y leídos que habría que registrar a mano, uno a uno, con su género y su
número de páginas. Son minutos por libro y decenas de libros. Con un JSON se resuelve de una vez,
y de paso queda una copia de la biblioteca fuera de la app.

## Alcance

**Entra**

- Una cuarta pestaña, **Perfil**, presentada como lista y pensada para crecer
- Exportar todos los libros a un archivo JSON, y ofrecerlo por el diálogo de compartir
- Importar libros desde un archivo JSON, elegido con el selector del sistema
- Un resumen de lo importado, con lo que se omitió y por qué

**No entra**

- Las **sesiones de lectura**. Se exportan y se importan solo libros — ver la advertencia de más
  abajo, porque tiene una consecuencia que conviene entender.
- Sincronización, copias automáticas y cualquier cosa que salga del dispositivo por su cuenta.
- Fusionar un libro importado con uno que ya exista: si coincide, se descarta, no se combina.

## Decisiones

- **Se llama Perfil**, aunque hoy no haya cuenta ni usuario. Ahí va a vivir el inicio de sesión
  cuando llegue, y renombrar una pestaña después de que la gente sepa dónde está es peor que
  llamarla desde el principio por lo que va a ser.
- **Va como cuarta pestaña**, con su lista dentro. Esconderla en la barra del Baúl la dejaría a
  mano solo desde una pantalla, cuando es de toda la app. Se aparta del diseño aprobado, que
  tiene tres pestañas; asumido a conciencia.
- **La lista arranca con un solo elemento**, el de exportar e importar, que abre su propia
  pantalla. Una lista de uno parece vacía, pero es la forma correcta para lo que viene detrás.
- **Importar añade, no reemplaza.** El caso real es sumar libros a una biblioteca que ya tiene
  cosas. Reemplazar sería un borrado masivo disfrazado de importación.
- **Un archivo con un libro roto no invalida el archivo.** Se importa todo lo válido y se informa
  de lo descartado. Un JSON escrito a mano va a tener erratas, y perder cuarenta libros buenos por
  una coma es hostil.
- **Los estados y los géneros viajan como texto**, no como el número que se guarda internamente.
  `"owned"` se lee y se escribe a mano; `1` no, y además ata el archivo a un detalle interno que
  puede cambiar.
- **Las portadas se quedan fuera.** En base64 engordan el archivo hasta hacerlo inmanejable —
  cincuenta libros pasarían de diez megas — y dejaría de poder abrirse en un editor para
  retocarlo a mano, que es justo lo que hace útil el formato. Las portadas se añaden desde la
  app, como hasta ahora.
- **El archivo lleva número de versión.** Es lo que permitirá leer archivos viejos cuando el
  formato cambie, sin adivinar.
- **Se trabaja con archivos, no con texto pegado.** Se valoró un campo grande donde pegar el
  JSON. Con decenas de libros, revisarlo dentro de un `TextEditor` en el móvil es impracticable,
  y el archivo cierra el círculo: exportas, editas en el ordenador, reimportas lo mismo. Ofrecer
  ambas vías sería doble interfaz, doble test y doble modo de fallo para algo que se usa un
  puñado de veces.
- **Importar abre el selector del sistema** (`fileImporter`), sin permisos ni acceso al
  almacenamiento.
- **Exportar abre el diálogo de compartir** (`ShareLink`), que deja mandarlo a donde sea:
  Archivos, AirDrop, correo. No se guarda a ningún sitio por su cuenta.

## Advertencia: una exportación no es una copia de seguridad completa

Solo se llevan los libros, y sin portada. **Las sesiones de lectura no**, y con ellas se queda
fuera todo el historial de Seguimiento.

Importar en un dispositivo nuevo dejaría la biblioteca entera pero la gráfica en blanco, y los
libros mostrarían su página actual sin ninguna sesión que la explique. La pantalla debe decirlo
donde se exporta, no en la letra pequeña.

Incluir las sesiones es un cambio aparte: obliga a decidir qué hacer cuando la sesión apunta a un
libro que no está en el archivo, y a resolver duplicados en un histórico que por decisión #17 no
se puede editar.

## El formato

```json
{
  "version": 1,
  "exportedAt": "2026-08-13T10:24:00Z",
  "books": [
    {
      "id": "8C6A1E52-1B0F-4E1A-9D3A-7C2F5B9E4A10",
      "title": "Sapiens",
      "author": "Yuval Noah Harari",
      "genre": "history",
      "pageCount": 512,
      "currentPage": 0,
      "status": "owned",
      "createdAt": "2026-08-01T18:00:00Z"
    }
  ]
}
```

| Campo | ¿Obligatorio? | Qué acepta |
|---|---|---|
| `title` | Sí | Texto no vacío |
| `genre` | Sí | Uno de los identificadores de género, en texto |
| `pageCount` | Sí | Entero mayor que cero |
| `author` | No | Texto; ausente significa sin autor |
| `currentPage` | No | Entero entre 0 y `pageCount`; por defecto 0 |
| `status` | No | `wishlist`, `owned`, `reading`, `finished`; por defecto `wishlist` |
| `id` | No | UUID; si ya existe ese libro, se descarta la entrada |
| `createdAt` | No | Fecha ISO 8601; por defecto, el momento de importar |

No hay campo de portada: ni se exporta ni se lee. Un libro importado empieza sin ella.

Los identificadores de género son los mismos que usa la app internamente — `novel`,
`science_fiction`, `historical_fiction`, `personal_development`… La lista completa está en
[`../features/README.md`](../features/README.md); la pantalla de ajustes debe poder mostrarla, o
el archivo se escribe a ciegas.

Un archivo escrito a mano puede quedarse en lo mínimo:

```json
{
  "version": 1,
  "books": [
    { "title": "Dune", "genre": "science_fiction", "pageCount": 412, "status": "owned" }
  ]
}
```

## Qué se omite al importar, y por qué

Un libro que falla se salta y la importación sigue: **nunca detiene el archivo entero**.

| Motivo | Ejemplo |
|---|---|
| Falta un campo obligatorio | Un libro sin `pageCount` |
| Género desconocido | `"genre": "novela"` en vez de `"novel"` |
| Número imposible | `pageCount` a 0, o `currentPage` mayor que el total |
| Estado desconocido | `"status": "leyendo"` en vez de `"reading"` |
| Ya existe ese `id` | Reimportar el mismo archivo dos veces |

El resumen agrupa por motivo, sin detallar línea a línea: lo justo para saber si el archivo
estaba bien escrito.

## La pantalla

Una sola pantalla, abierta desde el elemento de la lista de Perfil:

```
┌──────────────────────────────────┐
│  ‹ Perfil    Libros              │
│                                  │
│  Exportar                        │
│  Genera un archivo con tus 24    │
│  libros. No incluye portadas ni  │
│  sesiones de lectura.            │
│                                  │
│      [ Exportar libros ]         │
│                                  │
│  ──────────────────────────────  │
│                                  │
│  Importar                        │
│  Añade libros desde un archivo.  │
│  Los que ya estén no se repiten. │
│                                  │
│      [ Importar libros ]         │
│                                  │
│  ✓ 22 importados · 2 omitidos    │
│    2 con género desconocido      │
└──────────────────────────────────┘
```

El resumen aparece bajo el botón después de importar, y se queda hasta salir de la pantalla.
Cuenta cuántos entraron, cuántos se omitieron y por qué — sin ese porqué, un archivo escrito a
mano se corrige a ciegas.

## Criterios de aceptación

- [x] Perfil está en la barra de pestañas, accesible desde cualquier punto
- [x] Exportar e importar viven en su propia pantalla, abierta desde la lista de Perfil
- [x] Exportar abre el diálogo de compartir con el archivo ya generado
- [x] Importar abre el selector de archivos del sistema
- [x] Exportar produce un JSON con todos los libros, sin portadas
- [x] El archivo exportado se puede volver a importar y no duplica nada
- [x] Importar añade a la biblioteca existente en vez de reemplazarla
- [x] Un archivo escrito a mano con solo los campos obligatorios funciona
- [x] Un libro inválido no impide importar el resto
- [x] El resumen dice cuántos libros entraron y cuántos se omitieron, y por qué
- [x] La pantalla de exportar advierte de que ni las sesiones ni las portadas van incluidas
- [x] Un libro con portada se exporta y se reimporta sin ella, y sin romperse
- [x] Un archivo que no es JSON, o con una versión desconocida, da un error claro
- [x] La pantalla se ve correcta en los dos idiomas y los dos modos
- [x] Hay tests de la codificación, de la decodificación y de cada motivo de omisión

## Decisiones de producto que añade

A la lista de [`../features/README.md`](../features/README.md), al implementarse: que existe una
cuarta pestaña de Perfil, que importar añade sin reemplazar, y que una exportación cubre libros
pero no portadas ni historial de lectura.

También cambia la tabla de estructura de la app, que hoy describe tres pestañas.

## Lo que vendrá después en esta pestaña

Inicio de sesión, y lo que traiga consigo. No se diseña ahora, pero es la razón de que la
pestaña se llame Perfil y de que sea una lista en vez de una pantalla suelta de exportación.

## Cómo se validó

**Tests del formato**, que es donde está el riesgo: ida y vuelta completa conservando
identidad, fechas y autor; que las portadas no viajan; que estados y géneros se escriben como
palabras y no como números; el archivo mínimo de tres campos; el archivo vacío; el recorte de
espacios; **un test por cada motivo de omisión**, incluidos los campos obligatorios en cuatro
variantes y las páginas imposibles en otras cuatro; el archivo reimportado que no duplica nada;
dos entradas con el mismo `id` en el mismo archivo; y cinco formas de archivo que no es una
biblioteca, más la versión futura.

**El test que sostiene el requisito central:** un archivo con tres libros donde el del medio
tiene el número de páginas escrito como texto. Entran los otros dos y se cuenta uno omitido. Sin
la decodificación entrada por entrada, ese archivo perdería los tres.

**Tests del ViewModel:** que importar almacena, que añade sin reemplazar, que no repite lo que
ya estaba, que los libros buenos entran aunque otros fallen, y que un archivo ilegible reporta
error sin guardar nada.

**Un test de UI** que comprueba que la pestaña y la fila llevan a la pantalla, y que la
advertencia sobre portadas y sesiones está donde se decide exportar.

**En simulador:** Perfil en español claro, y la pantalla de archivo en inglés claro y español
oscuro.

**Sin automatizar:** la hoja de compartir y el selector de archivos, que son del sistema. Lo que
sí está probado es que el archivo se escribe y se puede volver a leer, y que lo que devuelve el
selector se procesa bien.

## Hallazgos

- **La decodificación tolerante es lo que hace real el requisito.** Un `pageCount` escrito como
  texto haría fallar la decodificación del array entero por defecto. Cada entrada se decodifica
  dentro de un envoltorio que devuelve `nil` en lugar de lanzar, y así el fallo se queda en su
  libro.
- **El resultado de leer una entrada no es un `Result`.** Swift exige que el caso de fallo
  conforme a `Error`, y un libro omitido no es un error: es un desenlace normal al leer un
  archivo escrito a mano. Se usa un tipo propio para no mentir sobre lo que es.
- **La cuarta pestaña no rompió ningún test de UI**, aunque cambia la barra. Los que navegan por
  pestañas las buscan por etiqueta, no por posición.
