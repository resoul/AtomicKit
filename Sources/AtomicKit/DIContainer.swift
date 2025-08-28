import Foundation

public protocol DIContainer {
    func register<T>(_ type: T.Type, scope: DIScope, factory: @escaping (DIContainer) -> T)
    func resolve<T>(_ type: T.Type) -> T
    func resolve<T>(_ type: T.Type) -> T?
    func createScope() -> DIContainer
    func dispose()
}

public final class DefaultDIContainer: DIContainer {
    public static let shared = DefaultDIContainer()

    private var factories: [String: (DIContainer) -> Any] = [:]
    private var scopes: [String: DIScope] = [:]
    private var singletons: [String: Any] = [:]
    private var scopedInstances: [String: Any] = [:]

    private let parent: DIContainer?
    private var children: [DefaultDIContainer] = []

    private init(parent: DIContainer? = nil) {
        self.parent = parent
    }

    public func register<T>(_ type: T.Type, scope: DIScope = .transient, factory: @escaping (DIContainer) -> T) {
        let key = String(describing: type)
        factories[key] = factory
        scopes[key] = scope
    }

    public func resolve<T>(_ type: T.Type) -> T {
        guard let instance: T = resolve(type) else {
            fatalError("Service of type \(type) not registered")
        }
        return instance
    }

    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        guard let scope = scopes[key] else {
            return parent?.resolve(type)
        }

        switch scope {
        case .singleton:
            if let instance = singletons[key] as? T {
                return instance
            }
            let newInstance = createInstance(type: type, key: key)
            singletons[key] = newInstance
            return newInstance

        case .scoped:
            if let instance = scopedInstances[key] as? T {
                return instance
            }
            let newInstance = createInstance(type: type, key: key)
            scopedInstances[key] = newInstance
            return newInstance

        case .transient:
            return createInstance(type: type, key: key)
        }
    }

    private func createInstance<T>(type: T.Type, key: String) -> T? {
        guard let factory = factories[key] else { return nil }
        return factory(self) as? T
    }

    public func createScope() -> DIContainer {
        let child = DefaultDIContainer(parent: self)
        children.append(child)
        return child
    }

    public func dispose() {
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