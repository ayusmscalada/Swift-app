# Strategies

Status: implemented · Signed off by client: —

The eight strategies of the original Windows app (its `Strategies/*.txt` files). Code: `App/Domain/Strategies/`, one file per strategy, sharing `StrategySupport.swift`.

**Sources:** the original's strategy files (JSON) and its bet and session logs (`Data/*BETS.csv`, `Data/*SESSIONS.csv`, July–Nov 2023). The logs give stake movements reliably. They do not give sides: their `winner` column does not line up with `win_status`. Where a rule could not be confirmed, it is marked **assumed**.

## Shared rules (all strategies)

| Rule | Behaviour | Source |
| --- | --- | --- |
| Win, loss, push | Read from the ledger, so payout settings apply (a tie is a push by default) | — |
| Tie | Stake and progression unchanged | Logs (Odd Even) |
| Stakes | In units, multiplied by the base unit | — |
| Stop profit / Stop loss | Money; stop betting for the rest of the session once reached | Strategy files, session logs (`STOP PROFIT`, `STOP LOSS`) |
| Losses in a row + Loss action | `STOP BET` stops; `REBET` restarts the progression and keeps betting | Strategy files, session logs |
| Pause after losses + Hands to skip | Skips that many hands after that many losses in a row | Strategy files, session logs |
| New shoe | Progression carries over; side rules look only at the current shoe | **assumed** |
| Results numbering | Ties are not counted (1st, 2nd, 3rd … Banker/Player result) | **assumed** |

## Strategies

| Strategy | Side | Stake | Defaults |
| --- | --- | --- | --- |
| **Martingale** | First bet Player, then the last winner | ×2 after a loss, back to start after a win | start 1, ×2 |
| **Grinding** | Same as Martingale | Oscar's Grind: same after a loss, +1 unit after a win, capped so each cycle ends one unit up | unit 1 |
| **Sequence** | Next side in the list after a loss, first after a win | Next stake after a loss, first after a win | `B,P,P,B,B,P,B,P` · `1,2,3` |
| **PATTERN** | IHG: Streak / Chop from the last two results, 2-2 from the last four (see below) | IHG run recovery (see below) | first P, run ends at 45, pause at 7 single wins |
| **Odd Even** | Odd-numbered results Banker, even-numbered Player (**assumed**) | Stake list: next after a loss, first after a win, restarts after the last | `1,2,3,6,12,24` |
| **ODD Diff** | Side that leads among odd-numbered results; no bet when level (**assumed**) | Stake list | `1,2,3` |
| **ODD Looser** | Side that trails among odd-numbered results; no bet when level (**assumed**) | Stake list | `1,2,3` |
| **ODD is God** | Winner of the last odd-numbered result (**assumed**) | Stake list | `1,2,3` |

## PATTERN = IHG ("Izak's Holy Grail")

Source: `IHG.pdf` and its reference sheet `IHG - Zumma 500 shoes - max bet 88 units - profits 3616.45 units.xls` (in `Documents/references`). A model of the rules below reproduces **all 36,529 hands** of the sheet: side, stake, win/loss and single-win count on every hand.

- **Side.** Ties are skipped, and the history runs on across shoes. First bet of the session: Player. After one result: follow it. Then look at the last two: same → bet the same (Streak); different → bet the opposite (Chop).
- **2-2.** When the last four are X X Y Y (for example B B P P), follow the 2-2: after a pair bet the opposite, after a change bet the same. Keep following it until one 2-2 bet loses.
- **Stake (a "run").** 1 unit after a loss. After a win, bet the run's loss rounded up to a whole unit, plus 1 (run at −20.15 → bet 22). The run closes as soon as it is ahead, and the stake goes back to 1.
- **Run limit.** After any bet of 45 units or more (win or lose), the run ends and the stake goes back to 1. The sheet's largest bet is 88 units.
- **Single wins.** A win between two losses counts as a single win; two wins in a row reset the count to 0. Virtual bets count too.
- **Pause.** While the count is 7 or more and a run is in progress, bets are virtual: picked and tracked, but not placed. Two wins in a row end the pause; the next real bet is 1 unit.

Confirmed from the logs: the stake list moves exactly as above (Odd Even sessions on 16–17 July 2023 go 2 → 4 → 6 → 12 → 24 → 48, back to 2 after a win and after losing 48, unchanged on a tie).

Left out on purpose, per the client: `DOMINOR`, `AI SELECTION`, the `rule_condition` field (for example Odd Even's `5,3,5,1`) and sides such as `W5,W1,W3,W4`.

Open questions are in `Docs/RuleQuestionLog.md`.
