import Foundation

/// Dependency wiring: one database and the repositories built on it.
@MainActor
final class AppEnvironment {
    let database: AppDatabase
    let sessions: SessionRepository
    let settings: SettingsRepository
    /// Set when the data file could not be opened and the app fell back to memory.
    let startupWarning: String?

    init(database: AppDatabase, startupWarning: String? = nil) {
        self.database = database
        self.sessions = SessionRepository(database)
        self.settings = SettingsRepository(database)
        self.startupWarning = startupWarning
    }

    static func live() -> AppEnvironment {
        do {
            return AppEnvironment(database: try AppDatabase.onDisk())
        } catch {
            // Keep the app usable; tell the user nothing will be saved.
            // swiftlint:disable:next force_try
            let memory = try! AppDatabase.inMemory()
            return AppEnvironment(
                database: memory,
                startupWarning: "The data file could not be opened (\(error.localizedDescription)). "
                    + "Working in memory: nothing will be saved."
            )
        }
    }
}
