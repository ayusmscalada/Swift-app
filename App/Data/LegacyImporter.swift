import Foundation
import GRDB

public enum LegacyFileFormat: String, Sendable {
    case sqlite = "SQLite 3 database"
    case access = "Microsoft Access database (Jet/ACE)"
    case xml = "XML"
    case ini = "INI configuration"
    case delimitedText = "CSV / delimited text"
    case text = "Plain text"
    case binary = "Unknown binary"
}

public struct LegacyFileReport: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let format: LegacyFileFormat
    public let byteCount: Int
    /// Findings: tables and columns, sections, or how many results the text holds.
    public let details: [String]
}

/// Week-1 inventory helper: identifies each file the client provides and what it seems to hold.
/// It reads formats and metadata only; mapping legacy fields into sessions is added once the
/// formats are known (see Docs: "Legacy data import").
public enum LegacyImporter {
    public static func inspect(_ url: URL) throws -> LegacyFileReport {
        let data = try Data(contentsOf: url)
        let format = detectFormat(data)
        var details: [String] = []

        switch format {
        case .sqlite:
            details = try describeSQLite(at: url)
        case .access:
            details = ["Needs an Access reader (e.g. mdbtools) or a CSV export from the Windows app."]
        case .xml, .ini, .delimitedText, .text:
            let text = decodeText(data)
            let lines = text.split(whereSeparator: \.isNewline)
            details.append("\(lines.count) lines")
            if format == .ini {
                let sections = lines.filter { $0.hasPrefix("[") && $0.hasSuffix("]") }
                details.append("Sections: " + sections.prefix(20).joined(separator: ", "))
            }
            let results = parseResultSequence(text)
            if !results.isEmpty {
                details.append("\(results.count) Banker/Player/Tie results found")
            }
        case .binary:
            details = ["Format not recognised; first bytes: " + data.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")]
        }

        return LegacyFileReport(url: url, format: format, byteCount: data.count, details: details)
    }

    public static func detectFormat(_ data: Data) -> LegacyFileFormat {
        if data.starts(with: Array("SQLite format 3".utf8) + [0]) { return .sqlite }
        if data.count >= 19 {
            let signature = String(decoding: data[4..<19], as: UTF8.self)
            if signature == "Standard Jet DB" || signature == "Standard ACE DB" { return .access }
        }
        if data.prefix(4096).contains(0) { return .binary }

        let text = decodeText(data).trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("<?xml") || text.hasPrefix("<") { return .xml }
        let lines = text.split(whereSeparator: \.isNewline)
        if lines.contains(where: { $0.hasPrefix("[") && $0.hasSuffix("]") }), lines.contains(where: { $0.contains("=") }) {
            return .ini
        }
        if lines.count > 1, lines.allSatisfy({ $0.contains(",") || $0.contains(";") || $0.contains("\t") }) {
            return .delimitedText
        }
        return .text
    }

    /// Reads results from text: separate tokens ("Banker, Player, T") or runs of letters ("BBPTP").
    /// Anything else is skipped.
    public static func parseResultSequence(_ text: String) -> [Outcome] {
        let separators = CharacterSet(charactersIn: ",;|\t ").union(.newlines)
        var outcomes: [Outcome] = []
        for token in text.components(separatedBy: separators) where !token.isEmpty {
            if let outcome = Outcome(token: token) {
                outcomes.append(outcome)
            } else if token.uppercased().allSatisfy({ "BPT".contains($0) }) {
                outcomes += token.uppercased().compactMap { Outcome(rawValue: String($0)) }
            }
        }
        return outcomes
    }

    private static func describeSQLite(at url: URL) throws -> [String] {
        var configuration = Configuration()
        configuration.readonly = true
        let queue = try DatabaseQueue(path: url.path, configuration: configuration)
        return try queue.read { db in
            let tables = try String.fetchAll(
                db, sql: "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
            )
            return try tables.map { table in
                let columns = try db.columns(in: table).map(\.name).joined(separator: ", ")
                let rows = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"\(table)\"") ?? 0
                return "\(table) (\(rows) rows): \(columns)"
            }
        }
    }

    private static func decodeText(_ data: Data) -> String {
        String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
    }
}
