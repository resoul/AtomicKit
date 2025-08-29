import Foundation
import Security
import CoreData

final class KeychainStorage: StorageService {
    private let service: String
    private let accessGroup: String?
    private let queue = DispatchQueue(label: "keychain-storage")

    init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    func get<T: Codable>(_ key: String, type: T.Type) async throws -> T? {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var query = self.baseQuery(for: key)
                query[kSecReturnData as String] = true
                query[kSecMatchLimit as String] = kSecMatchLimitOne

                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)

                guard status == errSecSuccess else {
                    if status == errSecItemNotFound {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(throwing: StorageError.keychainError(status))
                    }
                    return
                }

                guard let data = result as? Data else {
                    continuation.resume(throwing: StorageError.invalidData("Invalid keychain data"))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let value = try decoder.decode(T.self, from: data)
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

                    let query = self.baseQuery(for: key)
                    let status = SecItemCopyMatching(query as CFDictionary, nil)

                    if status == errSecSuccess {
                        // Update existing item
                        let updateQuery = [kSecValueData as String: data]
                        let updateStatus = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)

                        if updateStatus != errSecSuccess {
                            continuation.resume(throwing: StorageError.keychainError(updateStatus))
                            return
                        }
                    } else {
                        // Add new item
                        var addQuery = query
                        addQuery[kSecValueData as String] = data

                        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
                        if addStatus != errSecSuccess {
                            continuation.resume(throwing: StorageError.keychainError(addStatus))
                            return
                        }
                    }

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.serializationError(error))
                }
            }
        }
    }

    func remove(_ key: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let query = self.baseQuery(for: key)
                let status = SecItemDelete(query as CFDictionary)

                if status != errSecSuccess && status != errSecItemNotFound {
                    continuation.resume(throwing: StorageError.keychainError(status))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func exists(_ key: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                let query = self.baseQuery(for: key)
                let status = SecItemCopyMatching(query as CFDictionary, nil)
                continuation.resume(returning: status == errSecSuccess)
            }
        }
    }

    func clear() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                var query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: self.service
                ]

                if let accessGroup = self.accessGroup {
                    query[kSecAttrAccessGroup as String] = accessGroup
                }

                let status = SecItemDelete(query as CFDictionary)
                if status != errSecSuccess && status != errSecItemNotFound {
                    continuation.resume(throwing: StorageError.keychainError(status))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}