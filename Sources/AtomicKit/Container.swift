import Foundation

public protocol UseCase {}
public protocol Repository {}
public protocol DataSource {}
public protocol Service {}
public protocol ViewModel: AnyObject {}

public protocol Disposable {
    func dispose()
}

public enum ContainerScope {
    case singleton
    case transient
    case scoped
}

public protocol Container {
    func register<T>(_ type: T.Type, scope: ContainerScope, factory: @escaping (Container) -> T)
    func resolve<T>(_ type: T.Type) -> T
    func resolve<T>(_ type: T.Type) -> T?
    func createScope() -> Container
    func dispose()

    func registerSingleton<T>(_ type: T.Type, factory: @escaping (Container) -> T)
    func registerTransient<T>(_ type: T.Type, factory: @escaping (Container) -> T)
    func isRegistered<T>(_ type: T.Type) -> Bool
}

public final class SafeContainer: Container {
    public static let shared = SafeContainer()

    private var factories: [ObjectIdentifier: (Container) -> Any] = [:]
    private var scopes: [ObjectIdentifier: ContainerScope] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]
    private var scopedInstances: [ObjectIdentifier: Any] = [:]

    private let parent: Container?
    private var children: [SafeContainer] = []

    private let lock = NSRecursiveLock()
    private var resolutionStack: Set<ObjectIdentifier> = []

    private init(parent: Container? = nil) {
        self.parent = parent
    }

    public func register<T>(_ type: T.Type, scope: ContainerScope = .transient, factory: @escaping (Container) -> T) {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)
        factories[key] = factory
        scopes[key] = scope
    }

    public func registerSingleton<T>(_ type: T.Type, factory: @escaping (Container) -> T) {
        register(type, scope: .singleton, factory: factory)
    }

    public func registerTransient<T>(_ type: T.Type, factory: @escaping (Container) -> T) {
        register(type, scope: .transient, factory: factory)
    }

    public func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)
        return factories[key] != nil || parent?.isRegistered(type) == true
    }

    public func resolve<T>(_ type: T.Type) -> T {
        guard let instance: T = resolve(type) else {
            fatalError("Service of type \(type) not registered")
        }
        return instance
    }

    public func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)

        guard !resolutionStack.contains(key) else {
            fatalError("Circular dependency detected for type \(type)")
        }

        guard let scope = scopes[key] else {
            return parent?.resolve(type)
        }

        resolutionStack.insert(key)
        defer { resolutionStack.remove(key) }

        switch scope {
        case .singleton:
            if let instance = singletons[key] as? T {
                return instance
            }
            let newInstance = createInstance(type: type, key: key)
            if let instance = newInstance {
                singletons[key] = instance
            }
            return newInstance

        case .scoped:
            if let instance = scopedInstances[key] as? T {
                return instance
            }
            let newInstance = createInstance(type: type, key: key)
            if let instance = newInstance {
                scopedInstances[key] = instance
            }
            return newInstance

        case .transient:
            return createInstance(type: type, key: key)
        }
    }

    private func createInstance<T>(type: T.Type, key: ObjectIdentifier) -> T? {
        guard let factory = factories[key] else { return nil }
        return factory(self) as? T
    }

    public func createScope() -> Container {
        lock.lock()
        defer { lock.unlock() }

        let child = SafeContainer(parent: self)
        children.append(child)
        return child
    }

    public func dispose() {
        lock.lock()
        defer { lock.unlock() }

        // Dispose scoped instances
        for (_, instance) in scopedInstances {
            if let disposable = instance as? Disposable {
                disposable.dispose()
            }
        }
        scopedInstances.removeAll()

        // Dispose children
        children.forEach { $0.dispose() }
        children.removeAll()
    }
}
