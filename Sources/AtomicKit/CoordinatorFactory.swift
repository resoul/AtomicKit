import UIKit

public protocol CoordinatorFactory {
    func createCoordinator<T: Coordinator>(_ type: T.Type, navigationController: UINavigationController) -> T
    func createCoordinator<T: Coordinator>(_ type: T.Type) -> T
}

public final class DefaultCoordinatorFactory: CoordinatorFactory {
    private let container: Container

    public init(container: Container = DefaultContainer.shared) {
        self.container = container
    }

    public func createCoordinator<T: Coordinator>(
        _ type: T.Type,
        navigationController: UINavigationController
    ) -> T {
        // Create scoped container
        let scopedContainer = container.createScope()

        // Register navigationController in scoped container
        scopedContainer.register(UINavigationController.self, scope: .singleton) { _ in
            navigationController
        }

        return scopedContainer.resolve(type)
    }

    public func createCoordinator<T: Coordinator>(_ type: T.Type) -> T {
        return container.resolve(type)
    }
}
