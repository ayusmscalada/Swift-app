import Foundation
import BaccaratDomain

public enum CSVExporter {
    /// One row per hand: the result, the suggestion made before it, and what it paid.
    public static func sessionCSV(session: LoadedSession, result: SessionResult) -> String {
        var lines = ["session,shoe,hand,result,banker_pair,player_pair,suggested_side,units,stake,net,balance,reason"]
        for entry in result.ledger.entries {
            let hand = session.shoes[safe: entry.shoeIndex]?.hands[safe: entry.handIndex]
            lines.append([
                session.session.name,
                String(entry.shoeIndex + 1),
                String(entry.handIndex + 1),
                entry.outcome.rawValue,
                hand?.bankerPair == true ? "1" : "0",
                hand?.playerPair == true ? "1" : "0",
                entry.suggestion.side.rawValue,
                "\(entry.suggestion.units)",
                "\(entry.stake)",
                "\(entry.net)",
                "\(entry.balance)",
                entry.suggestion.reason,
            ].map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
