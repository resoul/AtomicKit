import Foundation
import Security
import CoreData

protocol CoreDataStorageService {
    func fetch<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate?) async throws -> [T]
    func fetchFirst<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate?) async throws -> T?
    func create<T: NSManagedObject>(_ entityType: T.Type) async throws -> T
    func save() async throws
    func delete<T: NSManagedObject>(_ object: T) async throws
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate?) async throws
    func count<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate?) async throws -> Int
}

final class CoreDataStorage: CoreDataStorageService, MigratableStorage {
    private let container: NSPersistentContainer
    private let mainContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext

    init(modelName: String, storeType: String = NSSQLiteStoreType) throws {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw StorageError.coreDataError(NSError(domain: "CoreDataStorage",
                                                   code: 1001,
                                                   userInfo: [NSLocalizedDescriptionKey: "Could not load Core Data model"]))
        }

        self.container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = storeType
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [storeDescription]

        self.mainContext = container.viewContext
        self.backgroundContext = container.newBackgroundContext()

        // Configure contexts
        mainContext.automaticallyMergesChangesFromParent = true
        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Load persistent store
        try loadPersistentStore()
    }

    private func loadPersistentStore() throws {
        var loadError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let error = loadError {
            throw StorageError.coreDataError(error)
        }
    }

    func fetch<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<T>(entityName: String(describing: entityType))
                    request.predicate = predicate

                    let results = try self.backgroundContext.fetch(request)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: StorageError.coreDataError(error))
                }
            }
        }
    }

    func fetchFirst<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws -> T? {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<T>(entityName: String(describing: entityType))
                    request.predicate = predicate
                    request.fetchLimit = 1

                    let results = try self.backgroundContext.fetch(request)
                    continuation.resume(returning: results.first)
                } catch {
                    continuation.resume(throwing: StorageError.coreDataError(error))
                }
            }
        }
    }

    func create<T: NSManagedObject>(_ entityType: T.Type) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                let entityName = String(describing: entityType)
                guard let entity = NSEntityDescription.entity(forEntityName: entityName,
                                                             in: self.backgroundContext) else {
                    let error = NSError(domain: "CoreDataStorage",
                                      code: 1002,
                                      userInfo: [NSLocalizedDescriptionKey: "Could not find entity: \(entityName)"])
                    continuation.resume(throwing: StorageError.coreDataError(error))
                    return
                }

                let object = T(entity: entity, insertInto: self.backgroundContext)
                continuation.resume(returning: object)
            }
        }
    }

    func save() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    if self.backgroundContext.hasChanges {
                        try self.backgroundContext.save()

                        // Save to main context as well
                        DispatchQueue.main.async {
                            do {
                                if self.mainContext.hasChanges {
                                    try self.mainContext.save()
                                }
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: StorageError.coreDataError(error))
                            }
                        }
                    } else {
                        continuation.resume()
                    }
                } catch {
                    continuation.resume(throwing: StorageError.coreDataError(error))
                }
            }
        }
    }

    func delete<T: NSManagedObject>(_ object: T) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                // Get object in background context
                do {
                    let objectInContext = try self.backgroundContext.existingObject(with: object.objectID)
                    self.backgroundContext.delete(objectInContext)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.coreDataError(error))
                }
            }
        }
    }

    func deleteAll<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<T>(entityName: String(describing: entityType))
                    request.predicate = predicate

                    let objects = try self.backgroundContext.fetch(request)
                    for object in objects {
                        self.backgroundContext.delete(object)
                    }

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.coreDataError(error))
                }
            }
        }
    }

    func count<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<T>(entityName: String(describing: entityType))
                    request.predicate = predicate

                    let count = try self.backgroundContext.count(for: request)
                    continuation.resume(returning: count)
                } catch {
                    continuation.resume(throwing: StorageError.coreDataError(error))
                }
            }
        }
    }

    // MARK: - MigratableStorage

//    func migrate(from version: Int, to version: Int) async throws {
        // Core Data handles migrations automatically with shouldMigrateStoreAutomatically
        // Custom migration logic can be added here if needed
//    }

    func currentVersion() -> Int {
        // Return current model version
        return container.managedObjectModel.versionIdentifiers.first as? Int ?? 1
    }

    // MARK: - Convenience Methods

    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let result = try block(self.backgroundContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func batchDelete<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
                    request.predicate = predicate

                    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                    batchDeleteRequest.resultType = .resultTypeObjectIDs

                    let result = try self.backgroundContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                    let objectIDArray = result?.result as? [NSManagedObjectID]

                    if let objectIDs = objectIDArray {
                        let changes = [NSDeletedObjectsKey: objectIDs]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes,
                                                          into: [self.mainContext])
                    }

                    continuation.resume()
                } catch {
                    continuation.resume(throwing: StorageError.coreDataError(error))
                }
            }
        }
    }
}
