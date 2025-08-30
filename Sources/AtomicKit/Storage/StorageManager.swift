import Foundation
import Security
import CoreData

public final class StorageManager {
    private let userDefaultsStorage: UserDefaultsStorage
    private let keychainStorage: KeychainStorage
    private let fileSystemStorage: FileSystemStorage
    private let coreDataStorage: CoreDataStorage?
    private let migrationManager: StorageMigrationManager

    public init() throws {
        self.userDefaultsStorage = UserDefaultsStorage(userDefaults: UserDefaults.standard)
        self.keychainStorage = KeychainStorage(service: Bundle.main.bundleIdentifier ?? "DefaultService",
                                             accessGroup: "com.example.app")
        self.fileSystemStorage = try FileSystemStorage(directory: FileManager.SearchPathDirectory.documentDirectory)

        self.coreDataStorage = try CoreDataStorage(modelName: "DataModel")

        self.migrationManager = StorageMigrationManager(migrations: [:])
    }

    public func storage(for type: StorageType) -> StorageService {
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
    public func getUserDefaults() -> UserDefaultsStorage { userDefaultsStorage }
    public func getKeychain() -> KeychainStorage { keychainStorage }
    public func getFileSystem() -> FileSystemStorage { fileSystemStorage }
    public func getCoreData() -> CoreDataStorage? { coreDataStorage }

    public func repository<T: NSManagedObject>(for entityType: T.Type) -> BaseRepository<T>? {
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
