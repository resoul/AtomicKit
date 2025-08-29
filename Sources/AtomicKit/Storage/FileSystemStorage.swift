import Foundation
import Security
import CoreData

final class FileSystemStorage: StorageService, CacheableStorage {
    private let baseURL: URL
    private let cache: MemoryCache<Data>
    private let queue = DispatchQueue(label: "filesystem-storage", attributes: .concurrent)
    private let fileManager = FileManager.default

    init(directory: FileManager.SearchPathDirectory = .documentDirectory,
         subdirectory: String = "Storage",
         cachePolicy: CachePolicy = .default) throws {
        let documentsURL = try fileManager.url(for: directory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: true)
        self.baseURL = documentsURL.appendingPathComponent(subdirectory)
        self.cache = MemoryCache<Data>(policy: cachePolicy)

        try createDirectoryIfNeeded()
    }

    func get<T: Codable>(_ key: String, type: T.Type) async throws -> T? {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let fileURL = self.baseURL.appendingPathComponent("\(key).json")

                // Check cache first
                if let cachedData = self.cache.get(key) {
                    do {
                        let decoder = JSONDecoder()
                        let value = try decoder.decode(T.self, from: cachedData)
                        continuation.resume(returning: value)
                        return
                    } catch {
                        // Cache corrupted, continue to file
                        self.cache.remove(key)
                    }
                }

                guard self.fileManager.fileExists(atPath: fileURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }

                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    let value = try decoder.decode(T.self, from: data)
                    self.cache.set(data, for: key)
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: StorageError.fileSystemError(error))
                }
            }
        }
    }

    func set<T: Codable>(_ value: T, for key: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(value)

                    let fileURL = self.baseURL.appendingPathComponent("\(key).json")
                    try data.write(to: fileURL)
                    self.cache.set(data, for: key)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.fileSystemError(error))
                }
            }
        }
    }

    func remove(_ key: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                let fileURL = self.baseURL.appendingPathComponent("\(key).json")

                do {
                    if self.fileManager.fileExists(atPath: fileURL.path) {
                        try self.fileManager.removeItem(at: fileURL)
                    }
                    self.cache.remove(key)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.fileSystemError(error))
                }
            }
        }
    }

    func exists(_ key: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                let fileURL = self.baseURL.appendingPathComponent("\(key).json")
                let exists = self.fileManager.fileExists(atPath: fileURL.path)
                continuation.resume(returning: exists)
            }
        }
    }

    func clear() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) {
                do {
                    let contents = try self.fileManager.contentsOfDirectory(at: self.baseURL,
                                                                           includingPropertiesForKeys: nil)
                    for fileURL in contents {
                        try self.fileManager.removeItem(at: fileURL)
                    }
                    self.cache.clear()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.fileSystemError(error))
                }
            }
        }
    }

    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: baseURL.path) {
            try fileManager.createDirectory(at: baseURL,
                                          withIntermediateDirectories: true)
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