import Foundation
import Security
import CoreData

final class UserDefaultsStorage: StorageService, CacheableStorage {
    private let userDefaults: UserDefaults
    private let cache: MemoryCache<Any>
    private let queue = DispatchQueue(label: "userdefaults-storage")

    init(userDefaults: UserDefaults = .standard, cachePolicy: CachePolicy = .default) {
        self.userDefaults = userDefaults
        self.cache = MemoryCache<Any>(policy: cachePolicy)
    }

    func get<T: Codable>(_ key: String, type: T.Type) async throws -> T? {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                // Check cache first
                if let cachedValue = self.cache.get(key) as? T {
                    continuation.resume(returning: cachedValue)
                    return
                }

                guard let data = self.userDefaults.data(forKey: key) else {
                    continuation.resume(returning: nil)
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let value = try decoder.decode(T.self, from: data)
                    self.cache.set(value, for: key)
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: StorageError.serializationError(error))
                }
            }
        }
    }

    func set<T: Codable>(_ value: T, for key: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(value)
                    self.userDefaults.set(data, forKey: key)
                    self.cache.set(value, for: key)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.serializationError(error))
                }
            }
        }
    }

    func remove(_ key: String) async throws {
        return await withCheckedContinuation { continuation in
            queue.async {
                self.userDefaults.removeObject(forKey: key)
                self.cache.remove(key)
                continuation.resume()
            }
        }
    }

    func exists(_ key: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                let exists = self.userDefaults.object(forKey: key) != nil
                continuation.resume(returning: exists)
            }
        }
    }

    func clear() async throws {
        return await withCheckedContinuation { continuation in
            queue.async {
                let domain = Bundle.main.bundleIdentifier!
                self.userDefaults.removePersistentDomain(forName: domain)
                self.cache.clear()
                continuation.resume()
            }
        }
    }

    // MARK: - CacheableStorage

    func invalidateCache() {
        cache.clear()
    }

    func invalidateCache(for key: String) {
        cache.remove(key)
    }

    func setCachePolicy(_ policy: CachePolicy) {
        // Would need to recreate cache with new policy
    }
}