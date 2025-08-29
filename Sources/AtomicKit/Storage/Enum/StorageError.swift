import Foundation
import Security
import CoreData

enum StorageError: Error, LocalizedError {
    case keychainError(OSStatus)
    case fileSystemError(Error)
    case coreDataError(Error)
    case serializationError(Error)
    case migrationFailed(String)
    case keyNotFound(String)
    case invalidData(String)
    case concurrencyError(String)

    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        case .coreDataError(let error):
            return "Core Data error: \(error.localizedDescription)"
        case .serializationError(let error):
            return "Serialization error: \(error.localizedDescription)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .keyNotFound(let key):
            return "Key not found: \(key)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .concurrencyError(let message):
            return "Concurrency error: \(message)"
        }
    }
}