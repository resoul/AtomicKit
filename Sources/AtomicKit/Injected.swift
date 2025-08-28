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