# Reference sessions

Each `.json` file here is one session recorded from the original Windows app. `ReferenceSessionTests` replays it through the macOS engine and checks it hand by hand on every test run.

```json
{
  "name": "S9-long-streak-01",
  "source": "Windows app v?.?, recorded 2026-10-xx, verified by client",
  "settings": { "strategy": "s9", "baseUnit": "10", "bankroll": "1000" },
  "hands": [
    { "result": "B", "suggestion": { "side": "P", "units": "1" }, "net": "-10", "balance": "990" },
    { "result": "P", "suggestion": { "side": "P", "units": "2" }, "net": "20", "balance": "1010" }
  ],
  "roads": { "bigRoad": "B|P", "bigEyeBoy": "...", "smallRoad": "...", "cockroachPig": "..." }
}
```

- `result`: `B`, `P` or `T`.
- `suggestion.side`: `B`, `P`, `T` or `-` (no bet). `units` is the stake in units.
- `net` and `balance`: what the original showed after the hand.
- Road strings: columns separated by `|`. Big Road uses `B`/`P` with ties left out (`BB|PPP|B`). Derived roads use `r`/`b` (`rr|b|rb`).
- Any field that is left out or set to `"..."` is not checked.
- Strategy checks run only once that strategy is implemented. Road checks always run.

`example-synthetic.json` was worked out by hand from the standard rules. It is not evidence of parity with the original; replace it with recorded sessions.
