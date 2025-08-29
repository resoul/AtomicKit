import Foundation

protocol StorageService {
    func get<T: Codable>(_ key: String, type: T.Type) async throws -> T?
    func set<T: Codable>(_ value: T, for key: String) async throws
    func remove(_ key: String) async throws
    func exists(_ key: String) async -> Bool
    func clear() async throws
}

protocol MigratableStorage {
//    func migrate(from version: Int, to version: Int) async throws
    func currentVersion() -> Int
}

protocol CacheableStorage {
    func invalidateCache()
    func invalidateCache(for key: String)
    func setCachePolicy(_ policy: CachePolicy)
}
