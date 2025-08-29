import Foundation
import Security
import CoreData

protocol CoreDataRepository {
    associatedtype Entity: NSManagedObject

    func findAll() async throws -> [Entity]
    func findBy(predicate: NSPredicate) async throws -> [Entity]
    func findFirst(predicate: NSPredicate) async throws -> Entity?
    func create() async throws -> Entity
    func save() async throws
    func delete(_ entity: Entity) async throws
    func deleteAll() async throws
    func count() async throws -> Int
}

class BaseRepository<T: NSManagedObject>: CoreDataRepository {
    typealias Entity = T

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage) {
        self.coreDataStorage = coreDataStorage
    }

    func findAll() async throws -> [T] {
        return try await coreDataStorage.fetch(T.self)
    }

    func findBy(predicate: NSPredicate) async throws -> [T] {
        return try await coreDataStorage.fetch(T.self, predicate: predicate)
    }

    func findFirst(predicate: NSPredicate) async throws -> T? {
        return try await coreDataStorage.fetchFirst(T.self, predicate: predicate)
    }

    func create() async throws -> T {
        return try await coreDataStorage.create(T.self)
    }

    func save() async throws {
        try await coreDataStorage.save()
    }

    func delete(_ entity: T) async throws {
        try await coreDataStorage.delete(entity)
    }

    func deleteAll() async throws {
        try await coreDataStorage.deleteAll(T.self)
    }

    func count() async throws -> Int {
        return try await coreDataStorage.count(T.self)
    }
}
