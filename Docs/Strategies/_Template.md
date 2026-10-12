# Strategy N: rule spec

Status: draft · Signed off by client: —

Built from the client's notes and the original app's observed behaviour. Implement only after sign-off, then remove `PendingSpecStrategy` from `App/Domain/Strategies/StrategyN.swift`.

1. **Trigger:** which history, pattern or road state starts a bet.
2. **Side:** how Banker or Player is chosen.
3. **Stake:** base unit, the progression table and how it moves on a win, loss or tie.
4. **Reset and stop:** when the cycle restarts (including whether it carries across shoes), and any session targets or stop values.
5. **Ties:** whether a tie counts as a push, is skipped, or affects the state.
6. **Display:** what the original shows: suggestion text, colours, counters.
7. **Parameters:** names and defaults stored in `StrategySettings.parameters`.
8. **Reference cases:** at least 3 recorded hand-by-hand sessions (10 for Strategy 9).
9. **Open rules:** numbered questions, also logged in `Docs/RuleQuestionLog.md`.
