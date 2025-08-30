import Foundation
import Security
import CoreData

public final class StorageManager {
    private let userDefaultsStorage: UserDefaultsStorage
    private let keychainStorage: KeychainStorage
    private let fileSystemStorage: FileSystemStorage
    private let coreDataStorage: CoreDataStorage?
    private let migrationManager: StorageMigrationManager

    init(
        userDefaults: UserDefaults = .standard,
        keychainService: String = Bundle.main.bundleIdentifier ?? "DefaultService",
        keychainAccessGroup: String? = nil,
        fileSystemDirectory: FileManager.SearchPathDirectory = .documentDirectory,
        coreDataModelName: String? = nil,
        migrations: [Int: StorageMigration] = [:]
    ) throws {
        self.userDefaultsStorage = UserDefaultsStorage(userDefaults: userDefaults)
        self.keychainStorage = KeychainStorage(service: keychainService,
                                             accessGroup: keychainAccessGroup)
        self.fileSystemStorage = try FileSystemStorage(directory: fileSystemDirectory)

        if let modelName = coreDataModelName {
            self.coreDataStorage = try CoreDataStorage(modelName: modelName)
        } else {
            self.coreDataStorage = nil
        }

        self.migrationManager = StorageMigrationManager(migrations: migrations)
    }

    func storage(for type: StorageType) -> StorageService {
        switch type {
        case .userDefaults:
            return userDefaultsStorage
        case .keychain:
            return keychainStorage
        case .fileSystem:
            return fileSystemStorage
        case .coreData:
            guard let coreDataStorage = coreDataStorage else {
                fatalError("CoreData storage not configured")
            }
            return CoreDataStorageAdapter(coreDataStorage: coreDataStorage)
        case .inMemory:
            fatalError("InMemory storage not implemented yet")
        }
    }

    // Convenience methods
    func getUserDefaults() -> UserDefaultsStorage { userDefaultsStorage }
    func getKeychain() -> KeychainStorage { keychainStorage }
    func getFileSystem() -> FileSystemStorage { fileSystemStorage }
    func getCoreData() -> CoreDataStorage? { coreDataStorage }

    func repository<T: NSManagedObject>(for entityType: T.Type) -> BaseRepository<T>? {
        guard let coreDataStorage = coreDataStorage else { return nil }
        return BaseRepository<T>(coreDataStorage: coreDataStorage)
    }
}

private final class CoreDataStorageAdapter: StorageService {
    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage) {
        self.coreDataStorage = coreDataStorage
    }

    func get<T: Codable>(_ key: String, type: T.Type) async throws -> T? {
        throw StorageError.invalidData("CoreData storage doesn't support key-value operations. Use repository pattern instead.")
    }

    func set<T: Codable>(_ value: T, for key: String) async throws {
        throw StorageError.invalidData("CoreData storage doesn't support key-value operations. Use repository pattern instead.")
    }

    func remove(_ key: String) async throws {
        throw StorageError.invalidData("CoreData storage doesn't support key-value operations. Use repository pattern instead.")
    }

    func exists(_ key: String) async -> Bool {
        return false
    }

    func clear() async throws {
        throw StorageError.invalidData("CoreData storage doesn't support clear operation. Use repository methods instead.")
    }
}
