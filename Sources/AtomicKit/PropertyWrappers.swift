import Foundation

@propertyWrapper
public struct Injected<T> {
    private let container: DIContainer

    public init(container: DIContainer = DefaultDIContainer.shared) {
        self.container = container
    }

    public var wrappedValue: T {
        return container.resolve(T.self)
    }
}

@propertyWrapper
public struct LazyInjected<T> {
    private let container: DIContainer
    private var _value: T?

    public init(container: DIContainer = DefaultDIContainer.shared) {
        self.container = container
    }

    public var wrappedValue: T {
        mutating get {
            if let value = _value {
                return value
            }
            let value: T = container.resolve(T.self)
            _value = value
            return value
        }
    }
}

@propertyWrapper
public struct Repository<T> where T: AtomicKit.Repository {
    @Injected private var repository: T

    public var wrappedValue: T {
        return repository
    }

    public init() {}
}

@propertyWrapper
public struct UseCase<T> where T: AtomicKit.UseCase {
    @Injected private var useCase: T

    public var wrappedValue: T {
        return useCase
    }

    public init() {}
}

@propertyWrapper
public struct CoordinatorInjected<T> where T: Coordinator {
    private let container: DIContainer

    public init(container: DIContainer = DefaultDIContainer.shared) {
        self.container = container
    }

    public var wrappedValue: T {
        return container.resolve(T.self)
    }
}

@propertyWrapper
public struct WeakCoordinator<T> where T: AnyObject {
    private weak var _coordinator: T?

    public var wrappedValue: T? {
        get { _coordinator }
        set { _coordinator = newValue }
    }

    public init() {}
}