# Skills del proyecto

Skills de agente instaladas a nivel de proyecto (carpeta `.agents/`, ignorada en git) para asistir en el desarrollo con Claude Code. Se instalan con `npx skills add <owner/repo>@<skill>` y quedan registradas en `skills-lock.json`.

## Instaladas

### ios-swift-development
```
npx skills add aj-geddes/useful-ai-prompts@ios-swift-development -y
```
Desarrollo iOS nativo con Swift: arquitectura MVVM, SwiftUI, networking con URLSession, Combine y persistencia con Core Data.

### core-data-expert
```
npx skills add avdlee/core-data-agent-skill@core-data-expert -y
```
Guía experta de Core Data: stack, fetch requests, migraciones, concurrencia y sincronización con CloudKit.

### ios-hig-design
```
npx skills add wondelai/skills@ios-hig-design -y
```
Diseño de interfaces nativas siguiendo las Apple Human Interface Guidelines: navegación, SF Symbols, accesibilidad, dark mode.

### swiftui-design-principles
```
npx skills add arjitj2/swiftui-design-principles@swiftui-design-principles -y
```
Principios de diseño para vistas y widgets SwiftUI pulidos, evitando resultados genéricos de UI generada por IA.

## Mantenimiento

```
npx skills update      # actualizar todas
npx skills list         # ver instaladas
npx skills experimental_install   # reinstalar desde skills-lock.json
```
