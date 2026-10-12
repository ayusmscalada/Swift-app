import Foundation
import GRDB

/// Owns the SQLite connection and the schema migrations.
public final class AppDatabase {
    public let writer: any DatabaseWriter

    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// The app's data file: ~/Library/Application Support/<folder>/data.sqlite
    /// (inside the sandbox container when the app is sandboxed).
    public static func onDisk(folderName: String = "BaccaratAssistant") throws -> AppDatabase {
        let fileManager = FileManager.default
        let folder = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(folderName, isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let queue = try DatabaseQueue(path: folder.appendingPathComponent("data.sqlite").path)
        return try AppDatabase(queue)
    }

    /// An empty in-memory database, for tests and as a fallback when the file can't be opened.
    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "session") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("created_at", .text).notNull()
                t.column("updated_at", .text).notNull()
                t.column("strategy_id", .text).notNull()
                t.column("start_bankroll", .text).notNull()
                t.column("notes", .text)
                t.column("legacy_extra", .text)
            }

            try db.create(table: "shoe") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("session_id", .integer).notNull().indexed()
                    .references("session", onDelete: .cascade)
                t.column("seq", .integer).notNull()
                t.column("started_at", .text).notNull()
                t.uniqueKey(["session_id", "seq"])
            }

            try db.create(table: "hand") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("shoe_id", .integer).notNull().indexed()
                    .references("shoe", onDelete: .cascade)
                t.column("seq", .integer).notNull()
                t.column("result", .text).notNull()
                t.column("banker_pair", .boolean).notNull().defaults(to: false)
                t.column("player_pair", .boolean).notNull().defaults(to: false)
                t.column("entered_at", .text).notNull()
                t.uniqueKey(["shoe_id", "seq"])
                t.check(sql: "result IN ('B','P','T')")
            }

            try db.create(table: "bet") { t in
                t.primaryKey("hand_id", .integer).references("hand", onDelete: .cascade)
                t.column("strategy_id", .text).notNull()
                t.column("side", .text).notNull()
                t.column("units", .text).notNull()
                t.column("stake", .text).notNull()
                t.column("net", .text).notNull()
                t.column("balance", .text).notNull()
                t.column("step", .integer)
                t.check(sql: "side IN ('B','P','T','-')")
            }

            try db.create(table: "strategy_settings") { t in
                t.primaryKey("strategy_id", .text)
                t.column("json", .text).notNull()
            }

            try db.create(table: "app_setting") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }
        }

        return migrator
    }
}
