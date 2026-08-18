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

- **Swift 5** / SwiftUI. App target deploys to **iOS 16.2**, iPhone only, portrait only. Raised from 16.0 deliberately in C15, for the exact form of ActivityKit's Live Activity API the Dynamic Island needs — not a side effect of wanting some other API.
- **Combine** for the reactive flow between layers.
- **Core Data** as the only storage (local). No backend for now.
- **Swift Testing** (`import Testing`, `@Test`, `#expect`) for unit tests. XCTest only in UI tests. Test targets deploy to iOS 16.2 as well — that is also Swift Testing's own floor, so the target cannot go lower without dropping the framework.
- No third-party dependencies: Apple SDKs only.
- **`tomotecaWidget`**, a Widget Extension target, hosts the reading session's Live Activity (Dynamic Island + Lock Screen). Its own deployment target is 16.2 too. `ReadingSessionActivityAttributes` (`Core/Domain/`) is the one file compiled into both the app and the extension — not a framework, just dual target membership. Everything that touches `ActivityKit` on the app side is behind `if #available(iOS 16.2, *)` and held as `Any?` by `ActiveSessionController` (see `ReadingSessionLiveActivityController`), so the app target's own code never assumes ActivityKit is present.

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
│   ├── Shared/                 # domain-aware UI shared by features (status → color + label)
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
│   └── Gallery/                # TokensGallery + preview-only catalog of every component
└── Assets.xcassets/
    └── DesignSystem/           # color sets backing AppColor (light + dark per color)
```

Targets use file-system-synchronized groups, so a file created on disk is picked up by Xcode with no `.pbxproj` edit.

A repository shared across features (e.g. `BookRepository`, used by both `BookList` and `ReadingSession`) lives in `Core/`, not duplicated per feature.

## Design system

The UI is built bottom-up from **tokens → components → feature views**. Nothing skips a level.

### Tokens are the single source of truth

`DesignSystem/Tokens/` is the **only** place where a color, a font, a spacing value or a corner radius is declared. Everything else consumes them by name.

- `AppColor` — the "Literary Warmth" palette, with semantic names only: `.background`, `.surface`, `.borderSubtle`, `.track`, `.textPrimary`, `.textSecondary`, `.brandPrimary` (bottle green), `.brandAccent` (coral), plus one color per book status in `AppColor.Status.{wishlist, owned, reading, finished}`. Backed by color sets in `Assets.xcassets/DesignSystem`, each with a light and a dark variant, so appearance switching needs no code.
- `AppFont` — **SF Pro Rounded** everywhere, reached through `design: .rounded` (a system face: nothing to bundle). Styles by **role**, not by size: `.largeTitle`, `.title`, `.headline`, `.body`, `.callout`, `.footnote`, `.caption`. Each one builds on a system text style so Dynamic Type keeps working.
- `Spacing` — a fixed 4pt-grid scale: `.xs` (4), `.sm` (8), `.md` (16), `.lg` (24), `.xl` (32).
- `Radius` — `.sm` (8), `.md` (12), `.lg` (16), `.pill`.

The status colors are deliberately not keyed by a domain type — the design system knows nothing about `Book`. Features map their own status enum onto them. Status is rendered as a colored dot plus colored text, never as a filled pill.

Screen designs live in [`docs/design/README.md`](docs/design/README.md) — see "Where work is written down" for the rest of the documentation map.

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

## Localization

The app ships in **Spanish and English**. Every string the user can read is localized —
there are no hardcoded literals in the UI, ever.

Strings live in `tomoteca/Localizable.xcstrings`, a String Catalog with `en` as the source
language and `es` alongside it. The project has `STRING_CATALOG_GENERATE_SYMBOLS` enabled, so
Xcode generates a type-safe symbol per key and **the compiler enforces the rule**: a key that
does not exist does not build.

```swift
Text(.tabTrunk)                       // ✅ key "tab.trunk", checked at compile time
Text("Baúl")                          // ❌ hardcoded, and Spanish-only
Text("tab.trunk")                     // ❌ string key, no compile-time check
```

- **Keys** use `area.snake_case`: `tab.trunk`, `book_form.title`, `session.finish_button`.
  Xcode turns them into camelCase symbols (`tab.trunk` → `.tabTrunk`).
- **Always fill in the `comment`** — it is the only context a translator gets.
- For a string that needs a runtime value, use the catalog's interpolation rather than
  building the sentence in Swift: word order differs between the two languages.
- Plurals go through the catalog's plural variations, never through `if count == 1`.
- Dates, times and numbers go through `Date.FormatStyle` and `NumberFormatter`, never through
  a hand-built string.
- **Permission strings** (camera, photo library, notifications) are localized too, in a
  separate `InfoPlist.xcstrings`.

The one exception is `DesignSystem/Gallery/`: it is debug-only developer tooling that never
reaches a user, so its labels stay as plain literals.

## Core Data

- The current model (`tomoteca.xcdatamodeld`) still holds the `Item` entity from the Xcode template: it must be replaced by `BookEntity`, `TagEntity` and `ReadingSessionEntity`.
- Relationships: `BookEntity` ↔ `TagEntity` (many-to-many), `BookEntity` → `ReadingSessionEntity` (one-to-many, cascade delete rule).
- Writes go through a background context; reads use `viewContext`. `automaticallyMergesChangesFromParent` is already enabled.
- `PersistenceController.preview` (in-memory) is the base for previews and tests; keep it seeded with representative data.
- The current `PersistenceController` calls `fatalError` on store-loading errors — replace it with real handling before shipping.
- Any schema change after data exists on device requires a new model version and a lightweight migration.

## Where work is written down

Before adding anything to `docs/`, find the right file. There is one place for each kind of thing.

| What | Where |
|---|---|
| How the app behaves today — product decisions, domain, statuses | `docs/features/README.md` |
| Why it came to behave that way — one file per change | `docs/cambios/` |
| How the v1 was built, milestone by milestone | `docs/features/hito-*.md` — **historical, never rewritten** |
| Screen designs and mockups | `docs/design/README.md` |
| Architecture and code rules | this file |

**New work is a change, not a milestone.** The eight milestones are closed. Improvements, fixes and extra features each get a numbered file in `docs/cambios/` (`C01`, `C02`…), with its type marked, following the same shape: scope, decisions, acceptance criteria, how it was validated, findings. Add a row to the index in `docs/cambios/README.md`.

**A change never redefines a product decision on its own.** When it adds or reverses one, edit the numbered list in `docs/features/README.md` — that list is the single source of truth for current behaviour — and let the change file explain why it moved.

**Definition of closed**, for both milestones and changes: acceptance criteria met, seen in the simulator in both languages and both appearances, covered by tests, and committed.

### Executing a change: implementation first, tests after

A change is executed in **two phases, with a stop in between**. Never do both in one run.

**Phase 1 — implementation.** Write the production code only: app code, model, strings, docs. Do not touch the test targets and do not run the test suite. Close the phase by building:

```bash
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Then **stop and report**: what changed, which files, what the acceptance criteria were, and what tests the change is going to need (new tests, and existing ones that will have to be adjusted and why). Ask for confirmation before going on.

**Phase 2 — tests.** Only after that confirmation: write and adjust the tests, run the suite, and fix what comes out.

Why the stop: adjusting existing tests is expensive, and it is wasted if the implementation still has to move. Confirming the implementation first means the tests are written once, against code that is already settled.

If a change turns out to need no test work at all, say so at the stop and wait for the go-ahead anyway — the stop is not skipped.

## Conventions

- **Code, type names and comments in English.** Documentation under `docs/` and commit messages in Spanish. UI copy is localized in both languages — see the localization section.
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

# Every test
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' test

# Available schemes and targets
xcodebuild -list -project tomoteca.xcodeproj
```

### Running tests without waiting five minutes

The full suite takes minutes, and nearly all of it is the UI tests: each one launches the app
from scratch. Running it after every edit is what makes a one-file change feel expensive.

**Run only what the change touched.** The unit suite is the cheap one — the whole of it finishes
in about a second, so there is no reason to skip it:

```bash
# Just the unit tests
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:tomotecaTests test

# One UI class, or one test inside it
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:tomotecaUITests/AddBookFlowUITests test
```

**Compile once, then re-run as often as needed.** `test` rebuilds all three targets every time;
splitting it skips that on every run after the first:

```bash
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' build-for-testing
xcodebuild -scheme tomoteca -destination 'platform=iOS Simulator,name=iPhone 17' test-without-building
```

**Keep the simulator booted.** A cold boot adds around two minutes of device migration before a
single test runs.

The full suite still runs before a change is called closed — the point is not to run it after
every keystroke on the way there.

## Project skills

`.agents/` (git-ignored) holds skills installed to assist development: `ios-swift-development`, `core-data-expert`, `ios-hig-design` and `swiftui-design-principles`. See `docs/proyect-skills.md` for installation and maintenance. Use them when designing UI or touching the Core Data stack.
