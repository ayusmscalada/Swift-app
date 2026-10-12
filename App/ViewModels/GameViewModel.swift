import Foundation
import Observation

/// Owns the open session. Every change is written to SQLite first, then the session is
/// reloaded and replayed through `SessionEngine`, so the screen always shows exactly what
/// the stored results produce.
@MainActor
@Observable
final class GameViewModel {
    private let env: AppEnvironment

    private(set) var sessions: [SessionRecord] = []
    private(set) var selectedSessionID: Int64?
    private(set) var loaded: LoadedSession?
    private(set) var result: SessionResult?
    private(set) var payouts: PayoutRules = .standard
    private(set) var strategySettings = StrategySettings()
    private(set) var bigRoadRows = 6

    /// Pair flags applied to the next entered result, then cleared.
    var nextBankerPair = false
    var nextPlayerPair = false

    var errorMessage: String?
    var isShowingReport = false
    var isImportingSequence = false
    var isInspectingLegacyFiles = false
    var legacyReports: [LegacyFileReport] = []

    init(environment: AppEnvironment) {
        env = environment
        errorMessage = environment.startupWarning
        perform {
            payouts = try env.settings.payoutRules()
            bigRoadRows = try env.settings.bigRoadRows()
        }
        refreshSessions()
        select(sessions.first?.id)
    }

    // MARK: Derived state

    var session: SessionRecord? { loaded?.session }
    var strategyID: StrategyID { session?.strategy ?? .martingale }
    var bankroll: Decimal { session?.bankroll ?? 0 }
    var currentShoeNumber: Int { loaded?.shoes.count ?? 0 }
    var currentShoe: LoadedShoe? { loaded?.shoes.last }
    var currentHistory: GameHistory { currentShoe?.history ?? GameHistory() }
    var roads: RoadmapSnapshot { result?.roads ?? RoadmapEngine.snapshot(for: GameHistory()) }
    var nextSuggestion: BetSuggestion { result?.nextSuggestion ?? .noBet() }
    var ledger: BetLedger { result?.ledger ?? BetLedger(startingBankroll: bankroll) }
    var patterns: PatternSummary { PatternAnalyzer().analyze(currentHistory) }
    var nextStake: Decimal {
        (nextSuggestion.units * strategySettings.baseUnit).rounded(scale: payouts.roundingScale)
    }

    /// Ledger rows of the current shoe, with the database id of each hand.
    var currentShoeRows: [HistoryRow] {
        guard let shoe = currentShoe else { return [] }
        let shoeIndex = (loaded?.shoes.count ?? 1) - 1
        let entries = ledger.entries.filter { $0.shoeIndex == shoeIndex }
        return zip(shoe.hands, entries).compactMap { hand, entry in
            guard let id = hand.id else { return nil }
            return HistoryRow(id: id, number: entry.handIndex + 1, hand: hand.hand, entry: entry)
        }
    }

    // MARK: Sessions

    func refreshSessions() {
        perform { sessions = try env.sessions.allSessions() }
    }

    func select(_ sessionID: Int64?) {
        selectedSessionID = sessionID
        reload(persistBets: false)
    }

    func newSession() {
        perform {
            let name = "Session " + Date().formatted(date: .abbreviated, time: .shortened)
            let created = try env.sessions.createSession(
                name: name,
                strategy: strategyID,
                bankroll: session?.bankroll ?? 1000
            )
            refreshSessions()
            select(created.id)
        }
    }

    func duplicate(_ sessionID: Int64) {
        guard let source = sessions.first(where: { $0.id == sessionID }) else { return }
        perform {
            let copy = try env.sessions.duplicateSession(sessionID, name: source.name + " copy")
            refreshSessions()
            select(copy?.id)
        }
    }

    func rename(_ sessionID: Int64, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        perform {
            try env.sessions.rename(sessionID, to: trimmed)
            refreshSessions()
            if sessionID == selectedSessionID { reload(persistBets: false) }
        }
    }

    func delete(_ sessionID: Int64) {
        perform {
            try env.sessions.deleteSession(sessionID)
            refreshSessions()
            if sessionID == selectedSessionID { select(sessions.first?.id) }
        }
    }

    // MARK: Game input

    func enter(_ outcome: Outcome) {
        guard let shoeID = currentShoe?.shoe.id else { return }
        let hand = Hand(outcome, bankerPair: nextBankerPair, playerPair: nextPlayerPair)
        perform {
            try env.sessions.appendHand(hand, toShoe: shoeID)
            nextBankerPair = false
            nextPlayerPair = false
            reload(persistBets: true)
        }
    }

    /// Removes the last result. On an empty shoe (other than the first) it removes the shoe.
    func undo() {
        guard let loaded, let shoe = loaded.shoes.last, let shoeID = shoe.shoe.id else { return }
        perform {
            if !shoe.hands.isEmpty {
                try env.sessions.removeLastHand(ofShoe: shoeID)
            } else if loaded.shoes.count > 1 {
                try env.sessions.deleteShoe(shoeID)
            } else {
                return
            }
            reload(persistBets: true)
        }
    }

    var canUndo: Bool {
        guard let loaded else { return false }
        return !(loaded.shoes.last?.hands.isEmpty ?? true) || loaded.shoes.count > 1
    }

    func edit(handID: Int64, to outcome: Outcome) {
        guard let record = loaded?.shoes.flatMap(\.hands).first(where: { $0.id == handID }) else { return }
        var hand = record.hand
        hand.outcome = outcome
        perform {
            try env.sessions.updateHand(handID, to: hand)
            reload(persistBets: true)
        }
    }

    func deleteHand(_ handID: Int64) {
        perform {
            try env.sessions.deleteHand(handID)
            reload(persistBets: true)
        }
    }

    func newShoe() {
        guard let sessionID = selectedSessionID else { return }
        perform {
            try env.sessions.startNewShoe(in: sessionID)
            reload(persistBets: true)
        }
    }

    // MARK: Strategy and money settings

    func setStrategy(_ id: StrategyID) {
        guard let sessionID = selectedSessionID, id != strategyID else { return }
        perform {
            try env.sessions.setStrategy(id, for: sessionID)
            reload(persistBets: true)
        }
    }

    func setBaseUnit(_ baseUnit: Decimal) {
        guard baseUnit > 0 else { return }
        var settings = strategySettings
        settings.baseUnit = baseUnit
        perform {
            try env.settings.save(settings, for: strategyID)
            reload(persistBets: true)
        }
    }

    /// Saves one strategy setting. An empty value restores the default (or turns a stop rule off).
    func setParameter(_ key: String, to value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        var settings = strategySettings
        guard (settings.parameters[key] ?? "") != trimmed else { return }
        settings.parameters[key] = trimmed.isEmpty ? nil : trimmed
        perform {
            try env.settings.save(settings, for: strategyID)
            reload(persistBets: true)
        }
    }

    func setBankroll(_ bankroll: Decimal) {
        guard let sessionID = selectedSessionID, bankroll >= 0 else { return }
        perform {
            try env.sessions.setBankroll(bankroll, for: sessionID)
            reload(persistBets: true)
        }
    }

    func savePayouts(_ rules: PayoutRules) {
        perform {
            try env.settings.save(rules)
            payouts = rules
            reload(persistBets: true)
        }
    }

    func setBigRoadRows(_ rows: Int) {
        let clamped = min(max(rows, 3), 12)
        perform {
            try env.settings.setBigRoadRows(clamped)
            bigRoadRows = clamped
        }
    }

    // MARK: Import, export, reports

    func importSequence(from url: URL) {
        perform {
            let text = try readText(url)
            let outcomes = LegacyImporter.parseResultSequence(text)
            guard !outcomes.isEmpty else {
                errorMessage = "No Banker / Player / Tie results were found in \(url.lastPathComponent)."
                return
            }
            let created = try env.sessions.importSession(
                name: "Imported " + url.deletingPathExtension().lastPathComponent,
                outcomes: outcomes,
                strategy: strategyID,
                bankroll: session?.bankroll ?? 1000
            )
            refreshSessions()
            select(created.id)
        }
    }

    func inspectLegacyFiles(_ urls: [URL]) {
        legacyReports = urls.compactMap { url in
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                return try LegacyImporter.inspect(url)
            } catch {
                errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
                return nil
            }
        }
    }

    var csvDocument: CSVDocument {
        guard let loaded, let result else { return CSVDocument(text: "") }
        return CSVDocument(text: CSVExporter.sessionCSV(session: loaded, result: result))
    }

    var csvFileName: String {
        (session?.name ?? "session").replacingOccurrences(of: "/", with: "-") + ".csv"
    }

    /// Replays every saved session with its own strategy settings, for the report table.
    func allSessionSummaries() -> [SessionSummaryRow] {
        sessions.compactMap { record in
            guard let id = record.id, let loaded = try? env.sessions.load(id) else { return nil }
            let settings = (try? env.settings.strategySettings(for: record.strategy)) ?? StrategySettings()
            let result = SessionEngine.run(SessionInput(
                shoes: loaded.histories,
                strategyID: record.strategy,
                settings: settings,
                startingBankroll: record.bankroll,
                payouts: payouts
            ))
            return SessionSummaryRow(
                id: id,
                name: record.name,
                strategy: record.strategy,
                hands: loaded.histories.map(\.count).reduce(0, +),
                summary: result.ledger.summary
            )
        }
    }

    // MARK: Private

    private func reload(persistBets: Bool) {
        guard let sessionID = selectedSessionID else {
            loaded = nil
            result = nil
            return
        }
        perform {
            guard let session = try env.sessions.load(sessionID) else {
                loaded = nil
                result = nil
                return
            }
            loaded = session
            strategySettings = try env.settings.strategySettings(for: session.session.strategy)
            let replay = SessionEngine.run(SessionInput(
                shoes: session.histories,
                strategyID: session.session.strategy,
                settings: strategySettings,
                startingBankroll: session.session.bankroll,
                payouts: payouts
            ))
            result = replay
            if persistBets {
                try env.sessions.replaceBets(for: session, result: replay, strategy: session.session.strategy)
            }
        }
    }

    private func readText(_ url: URL) throws -> String {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct HistoryRow: Identifiable, Hashable {
    let id: Int64
    let number: Int
    let hand: Hand
    let entry: LedgerEntry
}

struct SessionSummaryRow: Identifiable, Hashable {
    let id: Int64
    let name: String
    let strategy: StrategyID
    let hands: Int
    let summary: LedgerSummary
}
