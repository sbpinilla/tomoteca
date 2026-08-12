# Tomoteca

Native iOS app to manage a personal library: track books I want to read or buy, follow their status, and time reading sessions.

> **Current state:** the repository is still the bare Xcode SwiftUI + Core Data template — nothing in this document is implemented yet. It describes the target architecture, not existing code.

## Product

### Book catalog
- Manual book entry (title, author, page count, notes).
- Every book has a **status** in its lifecycle:
  - `wishlist` — want to buy it
  - `owned` — bought, not read yet
  - `reading` — currently reading
  - `finished` — done
- Books can be freely **tagged** (user-created tags, many-to-many).
- The list can be filtered by status and by tag.

### Reading sessions
- A button starts a session with a configurable duration (e.g. 10, 15, 30 min).
- A visible timer runs during the session.
- When the time is up, the app notifies the user and **asks for the page they stopped at**.
- The session is stored against the book: duration, date, starting page and ending page.
- The book's progress (current page) is updated from the latest session.

## Stack

- **Swift 5** / SwiftUI. App target deploys to **iOS 16.0**, iPhone only, portrait only.
- **Combine** for the reactive flow between layers.
- **Core Data** as the only storage (local). No backend for now.
- **Swift Testing** (`import Testing`, `@Test`, `#expect`) for unit tests. XCTest only in UI tests. Test targets deploy to iOS 16.0 as well — that is also Swift Testing's own floor, so the target cannot go lower without dropping the framework.
- No third-party dependencies: Apple SDKs only.

### iOS 16 constraints

Navigation uses `NavigationStack` with value-based destinations. These iOS 17 APIs are **not available** and must not be used in app code:

| Not available | Use instead |
|---|---|
| `@Observable` (iOS 17) | `ObservableObject` + `@Published` |
| `#Preview` macro (iOS 17) | `PreviewProvider` structs |
| `ContentUnavailableView` (iOS 17) | the project's own `TMEmptyState` component |
| `SwiftData` (iOS 17) | Core Data |
| Two-parameter `.onChange(of:) { old, new in }` (iOS 17) | the single-parameter iOS 16 signature |

If a target bump is ever considered, do it deliberately and revisit this table — do not raise it as a side effect of wanting one API.

## Architecture

MVVM **organized by feature**, not by layer type. Each feature is self-contained.

```
View (SwiftUI)  ──observes──▶  ViewModel  ──calls──▶  Repository (protocol)
                                                            │
                                              ┌─────────────┴─────────────┐
                                        CoreDataRepository        (future) RemoteRepository
```

### Rules

1. **The view knows nothing about persistence.** It only talks to its ViewModel. No `@FetchRequest` or `NSManagedObjectContext` inside views.
2. **The ViewModel knows nothing about Core Data.** It depends on a repository *protocol*, never on the concrete implementation. This makes it possible to swap Core Data for a remote repository, or for a fake in tests, without touching the ViewModel.
3. **`NSManagedObject` instances never leave the data layer.** The repository maps Core Data entities to domain structs (`Book`, `ReadingSession`, `Tag`) and returns those. The domain layer is `Sendable` and has no Core Data references.
4. **ViewModels are `@MainActor` and `ObservableObject`**, using `@Published` for view state. They expose a state, not a scattered set of flags.
5. **Repositories expose `AnyPublisher` or `async throws`**, and in both cases deliver on the main thread before reaching the ViewModel.
6. **Dependency injection is constructor-based.** The ViewModel receives its repository; the view receives an already-built ViewModel (or creates it with `@StateObject` at the composition point).

### Folder structure

```
tomoteca/
├── App/                        # tomotecaApp.swift, root composition, DI
├── Core/
│   ├── Persistence/            # PersistenceController, Core Data stack
│   ├── Domain/                 # shared domain models (Book, Tag, ReadingSession)
│   └── Extensions/             # cross-cutting helpers
├── Features/
│   ├── BookList/
│   │   ├── Views/              # BookListView, BookRowView…
│   │   ├── ViewModels/         # BookListViewModel
│   │   └── Repositories/       # BookRepository (protocol) + CoreDataBookRepository
│   ├── BookDetail/
│   ├── BookForm/               # create and edit
│   └── ReadingSession/
│       ├── Views/              # ReadingSessionView, TimerView, PagePromptView
│       ├── ViewModels/         # ReadingSessionViewModel (timer, session state)
│       └── Repositories/
├── DesignSystem/
│   ├── Tokens/                 # AppColor, AppFont, Spacing, Radius — the only place values are declared
│   ├── Components/             # domain-agnostic reusable components (TMButton, TMChip…)
│   └── Gallery/                # preview-only catalog of every component
└── Resources/                  # Assets.xcassets, Localizable
```

A repository shared across features (e.g. `BookRepository`, used by both `BookList` and `ReadingSession`) lives in `Core/`, not duplicated per feature.

## Design system

The UI is built bottom-up from **tokens → components → feature views**. Nothing skips a level.

### Tokens are the single source of truth

`DesignSystem/Tokens/` is the **only** place where a color, a font, a spacing value or a corner radius is declared. Everything else consumes them by name.

- `AppColor` — semantic names, never literal ones: `.textPrimary`, `.textSecondary`, `.background`, `.surface`, `.accent`, `.destructive`, plus one per book status (`.statusWishlist`, `.statusOwned`, `.statusReading`, `.statusFinished`). Backed by color sets in `Assets.xcassets` so light/dark mode comes for free.
- `AppFont` — styles by **role**, not by size: `.largeTitle`, `.title`, `.headline`, `.body`, `.callout`, `.caption`. Each one builds on a system text style so Dynamic Type keeps working.
- `Spacing` — a fixed scale: `.xs` (4), `.sm` (8), `.md` (16), `.lg` (24), `.xl` (32).
- `Radius` — `.sm`, `.md`, `.lg`, `.pill`.

Banned outside `DesignSystem/Tokens/`:

```swift
.font(.system(size: 17))        // ❌  use .font(AppFont.body)
.foregroundStyle(.gray)         // ❌  use .foregroundStyle(AppColor.textSecondary)
Color(red: 0.2, green: 0.4…)    // ❌  add a color set + an AppColor case
.padding(16)                    // ❌  use .padding(Spacing.md)
```

This applies to components too, not just to screens: a component consumes tokens, it never defines values.

### Components

Every recurring UI element — a button, a title, a chip, a text field, a card, an empty state — is written **once** and reused everywhere. Prefix them with `TM` so they never collide with SwiftUI types (`TMButton`, `TMTextField`, `TMChip`, `TMCard`, `TMEmptyState`).

Where a component lives is decided by one question: **does it know about the domain?**

| Component | Knows about `Book`? | Lives in |
|---|---|---|
| `TMButton`, `TMChip`, `TMEmptyState` | No | `DesignSystem/Components/` |
| `BookRowView`, `ReadingTimerView` | Yes | its own feature, under `Views/` |

**Promotion rule:** the moment a feature component is needed by a second feature, move it to `DesignSystem/Components/`, strip the domain out of it, and pass what it needs as parameters. Do not import one feature from another.

### Working rule: look before you build

Before writing any UI element, check `DesignSystem/Components/` and the feature's own `Views/`. If something close already exists, extend it with a parameter instead of forking it. Only create a new component when nothing fits — and then use it everywhere that case appears, including the places that had it inlined.

`DesignSystem/Gallery/` holds a preview-only view rendering every component in all its states. It is the catalog to check first, and every new component must be added to it.

### Component rules

- Components are stateless and dumb: they take data and closures, and hold no business logic and no ViewModel.
- They never fetch, never format domain rules, never navigate. They render and report back through callbacks.
- Variants go through an `enum` (`TMButton.Style.primary / .secondary / .destructive`), not through a pile of booleans.
- Every component ships with a `PreviewProvider` covering its variants, plus dark mode (the `#Preview` macro is iOS 17+, out of reach here).

## Core Data

- The current model (`tomoteca.xcdatamodeld`) still holds the `Item` entity from the Xcode template: it must be replaced by `BookEntity`, `TagEntity` and `ReadingSessionEntity`.
- Relationships: `BookEntity` ↔ `TagEntity` (many-to-many), `BookEntity` → `ReadingSessionEntity` (one-to-many, cascade delete rule).
- Writes go through a background context; reads use `viewContext`. `automaticallyMergesChangesFromParent` is already enabled.
- `PersistenceController.preview` (in-memory) is the base for previews and tests; keep it seeded with representative data.
- The current `PersistenceController` calls `fatalError` on store-loading errors — replace it with real handling before shipping.
- Any schema change after data exists on device requires a new model version and a lightweight migration.

## Conventions

- **Code, type names and comments in English.** Documentation under `docs/`, commit messages and UI copy in Spanish.
- One type per file, file named after the type.
- Small, composable views: if a `body` grows past ~50 lines, extract subviews.
- No business logic in views; no presentation logic in repositories.
- No raw colors, fonts, spacings or radii outside `DesignSystem/Tokens/` — see the design system section.
- Reuse before you write: check `DesignSystem/Components/` and the gallery before adding any UI element.
- Domain errors are modeled with `enum: Error`, not strings.
- Unit tests cover ViewModels and repositories using protocol fakes, not the real database.

## Commands

```bash
# Build
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' build

# Tests
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' test

# Available schemes and targets
xcodebuild -list -project tomoteca.xcodeproj
```

## Project skills

`.agents/` (git-ignored) holds skills installed to assist development: `ios-swift-development`, `core-data-expert`, `ios-hig-design` and `swiftui-design-principles`. See `docs/proyect-skills.md` for installation and maintenance. Use them when designing UI or touching the Core Data stack.
