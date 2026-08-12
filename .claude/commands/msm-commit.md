---
description: Propone un mensaje de commit en formato Conventional Commits, en español, a partir de los cambios trackeados y sin trackear del repo. No ejecuta el commit.
---

Vas a proponer un mensaje de commit siguiendo Conventional Commits, con el título y el cuerpo **en español**, que cubra **todos** los cambios pendientes del repo: modificados, nuevos (sin trackear) y eliminados. No debes ejecutar `git add` ni `git commit` en ningún caso — el usuario stagea y commitea manualmente.

Un archivo nuevo sin trackear es un cambio como cualquier otro: debe analizarse y reflejarse en el mensaje igual que uno modificado o eliminado. "No stagear/commitear automáticamente" no significa "ignorarlo".

Pasos:

1. Ejecuta en paralelo:
   - `git status` (para ver el estado completo: modificados, staged, sin trackear, eliminados)
   - `git diff` (cambios trackeados sin stagear, incluye eliminaciones de archivos trackeados)
   - `git diff --staged` (cambios ya en stage)

2. Para cada archivo sin trackear que liste `git status`, lee su contenido (Read, o `git diff --no-index /dev/null <archivo>`) para entender qué aporta realmente, no solo el nombre.

3. Con base en el contenido real de todos los cambios (modificados, nuevos y eliminados), determina el tipo de Conventional Commits que mejor aplica:
   `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
   Si el cambio toca varios ámbitos, usa el tipo del cambio más significativo.

4. Redacta el mensaje con este formato:

   ```
   tipo(alcance opcional): título breve en español, en minúscula, sin punto final

   Cuerpo opcional en español, ligado al código: qué archivo, tipo, función o símbolo
   cambia y qué hace ahora distinto (moved/renamed/added/removed, con nombres concretos
   del diff). Nada de narrativa de proceso ni justificación de por qué se decidió hacer
   el trabajo — eso va en la descripción del PR o en docs, no en el commit. Omite el
   cuerpo si el cambio es trivial o un solo archivo evidente por el título.
   ```

5. Entrega el resultado así, y nada más:
   - El mensaje de commit propuesto, en un bloque de código listo para copiar, cubriendo todos los archivos pendientes (modificados + nuevos + eliminados).
   - La lista de archivos que cubre el mensaje, agrupados por estado (nuevo / modificado / eliminado).

   No incluyas el comando `git add` ni `git commit` en la respuesta: el usuario stagea y commitea por su cuenta.
