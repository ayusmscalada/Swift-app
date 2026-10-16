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

## 24-hour trial

Builds include a 24-hour trial (`App/Support/Trial/`). It runs in the background and shows nothing on screen:

- The first launch is recorded in **Google time** (the `Date` header of `https://www.google.com/generate_204`) in the app's settings (UserDefaults).
- Every launch, and every 60 seconds while running, the time is checked with Google. Between checks the countdown uses the Mac's monotonic clock, so changing the date has no effect.
- No internet: the window's controls and menu actions are disabled until Google answers again (retry every 10 seconds). Close, minimize and zoom still work.
- After 24 hours the app closes at once, even while running, and every later launch closes it straight away.
- To build without the trial, set `TrialGuard.isEnabled = false`.
- To restart the trial on a test Mac: `defaults delete com.example.baccarat.assistant trialRecord` (for the sandboxed app, the settings file is under `~/Library/Containers/com.example.baccarat.assistant/`).

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
- **UI layout** follows the original's main screen on its navy background: strategy, win/loss conditions, stop rules, consecutive win/loss rules, dummy bet and Start / Stop Auto Bet on the left; entry (results or cards), bet history and roads in the middle; session, inactive count, last hand's cards, next bet, balance and profit on the right. The Mac app does not connect to a casino: Auto Bet turns the strategy's betting on or off for the hands you enter.
