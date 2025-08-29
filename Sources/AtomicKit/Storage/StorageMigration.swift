import Foundation
import Security
import CoreData

final class StorageMigrationManager {
    private let migrations: [Int: StorageMigration]

    init(migrations: [Int: StorageMigration] = [:]) {
        self.migrations = migrations
    }

    func migrate(_ storage: StorageService & MigratableStorage, to targetVersion: Int) async throws {
        let currentVersion = storage.currentVersion()

        guard currentVersion < targetVersion else { return }

        for version in (currentVersion + 1)...targetVersion {
            guard let migration = migrations[version] else {
                throw StorageError.migrationFailed("No migration found for version \(version)")
            }

            try await migration.migrate(storage: storage)
        }
    }
}

protocol StorageMigration {
    func migrate(storage: StorageService) async throws
}