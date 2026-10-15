# Baccarat Assistant for macOS

A native macOS rebuild of the client's Windows Baccarat analysis tool: Swift 5 language mode, SwiftUI, MVVM, SQLite (GRDB), macOS 14+, Apple Silicon.

## Build and run

You need a Mac with Xcode 26.6. GRDB is used from a local copy; get it once with:

```sh
mkdir -p Packages && cd Packages && git clone --depth 1 https://github.com/groue/GRDB.swift.git
```

**App project (recommended):** install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and generate the project:

```sh
brew install xcodegen
xcodegen generate
open BaccaratAssistant.xcodeproj
```

Set your signing team in the target, then run (⌘R). For delivery, Archive and notarise a Developer ID build. Run `xcodegen generate` again after editing `project.yml` or adding files.

**Quick run without XcodeGen:** open the root `Package.swift` in Xcode, pick the `BaccaratApp` scheme and run.

## Layout

```
App/                      The whole app, one target
  Views/, ViewModels/,
  Support/                SwiftUI views, view models, theme, CSV document
  Domain/                 Pure logic. No UI or database imports.
    Models/               Outcome, Hand, GameHistory
    Roadmaps/             Big Road, derived roads, grid layout (dragon tail), Ask predictions
    Patterns/             Streak and chop detection
    Betting/              Payout rules, BetLedger, statistics
    Strategies/           BaccaratStrategy protocol, registry, shared stake and stop rules, one file per strategy
    Session/              SessionEngine: replays a session from its results
  Data/                   GRDB schema and migrations, repositories, legacy-file inspection, CSV export
Packages/GRDB.swift/      Local copy of GRDB (not committed; see above)
project.yml               XcodeGen spec for the .app
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

- **Strategies:** Martingale, Grinding, Sequence, PATTERN, Odd Even, ODD Diff, ODD Looser and ODD is God are implemented, with stop profit, stop loss, and stop / rebet / pause rules after wins or losses in a row. Stake movements match the original's logs; some side rules are assumed until the client confirms them (`Docs/Strategies/Strategies.md`, `Docs/RuleQuestionLog.md`).
- **Road details:** tie placement, Bead Plate presence and grid sizes follow standard rules until they are checked against the original.
- **Pattern rules, report formats, settings** beyond the above, and **legacy data import mapping** depend on the EXE, the videos and the data files.
- **UI layout** follows the original's main screen (strategy and win/loss conditions on the left, bet history in the middle, session and balance on the right), rearranged for macOS. Auto-betting parts of the original (casino cards, inactive-count dummy bets, Stop Auto Bet) are left out.
