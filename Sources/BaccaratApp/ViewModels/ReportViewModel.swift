import Foundation
import BaccaratDomain
import BaccaratData

/// Figures for the statistics panel and the report sheet, all derived from the ledger and hands.
struct ReportViewModel {
    let session: LoadedSession?
    let ledger: BetLedger

    var statistics: OutcomeStatistics {
        StatsService.statistics(for: session?.histories ?? [])
    }

    var currentShoeStatistics: OutcomeStatistics {
        StatsService.statistics(for: session?.histories.suffix(1).map { $0 } ?? [])
    }

    var summary: LedgerSummary { ledger.summary }
}
