# Baccarat Assistant for macOS

A native macOS rebuild of the client's Windows Baccarat analysis tool: Swift 5 language mode, SwiftUI, MVVM, SQLite (GRDB), macOS 14+, Apple Silicon.

## Build and run

You need a Mac with Xcode 26.6.

**Quick start:** open `Package.swift` in Xcode, pick the `BaccaratApp` scheme and run (⌘R). Run the tests with ⌘U, or `swift test` in Terminal.

**Sandboxed .app (for delivery):** install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and generate the project:

```sh
brew install xcodegen
xcodegen generate
open BaccaratAssistant.xcodeproj
```

Set your signing team in the target, then Archive and notarise for a Developer ID build.

## Layout

```
Sources/
  BaccaratDomain/   Pure logic. No UI or database imports.
    Models/         Outcome, Hand, GameHistory
    Roadmaps/       Big Road, derived roads, grid layout (dragon tail), Ask predictions
    Patterns/       Streak and chop detection
    Betting/        Payout rules, BetLedger, statistics
    Strategies/     BaccaratStrategy protocol, registry, Strategy1–6 and 9
    Session/        SessionEngine: replays a session from its results
  BaccaratData/     GRDB schema and migrations, repositories, legacy-file inspection, CSV export
  BaccaratApp/      SwiftUI app: view models and views
Tests/
  BaccaratDomainTests/   Road, payout, ledger, pattern and engine tests; Reference/ parity sessions
  BaccaratDataTests/     Repository, settings, importer and CSV tests (in-memory SQLite)
Docs/
  Strategies/       One rule spec per strategy (template provided)
  RuleQuestionLog.md
```

Nothing derived is stored. Roads, strategy state, the ledger and statistics are rebuilt from the saved results on every change, so undo and edit are exact. The `bet` table keeps a snapshot of what was suggested.

## What works now

- Result entry (buttons, or B / P / T keys), pair flags, undo, edit or delete any hand, new shoe
- Sessions: create, rename, duplicate, delete; auto-saved to `~/Library/Application Support/BaccaratAssistant/data.sqlite`
- Bead Plate, Big Road with ties, pairs and dragon tail, Big Eye Boy, Small Road, Cockroach Pig, and Ask predictions
- Streak and chop detection, shoe statistics, P/L ledger with peak and drawdown, a report across sessions, CSV export
- Payout settings (commission, tie rules, rounding) and Big Road height
- File → Import Result Sequence: builds a session from text such as `B P T` or `BBPTP`
- File → Inspect Windows Data Files: identifies SQLite, Access, INI, XML and text files and lists their tables and columns (week-1 inventory)

## Waiting on analysis of the original

- **Strategies 1–6 and 9** are placeholders that never bet. Each needs a signed-off spec (`Docs/Strategies/_Template.md`) before it is implemented, so the app never shows an invented rule.
- **Road details:** tie placement, Bead Plate presence and grid sizes follow standard rules until they are checked against the original.
- **Pattern rules, report formats, settings** beyond the above, and **legacy data import mapping** depend on the EXE, the videos and the data files.
- **UI layout** is provisional until it is matched to the original's screenshots.

## Parity testing

Record sessions from the Windows app as JSON in `Tests/BaccaratDomainTests/Reference/` (format in that folder's README). Every test run replays them and compares roads, suggestions, net and balance hand by hand.
