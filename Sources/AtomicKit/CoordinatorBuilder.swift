import UIKit

public final class CoordinatorBuilder {
    private let container: Container

    public init(container: Container = DefaultContainer.shared) {
        self.container = container
    }

    public func build<T: Coordinator>(_ coordinatorType: T.Type) -> CoordinatorConfiguration<T> {
        return CoordinatorConfiguration(container: container, coordinatorType: coordinatorType)
    }
}

public final class CoordinatorConfiguration<T: Coordinator> {
    private let container: Container
    private let coordinatorType: T.Type
    private var navigationController: UINavigationController?
    private var parentCoordinator: ParentCoordinator?

    internal init(container: Container, coordinatorType: T.Type) {
        self.container = container
        self.coordinatorType = coordinatorType
    }

    public func with(navigationController: UINavigationController) -> CoordinatorConfiguration<T> {
        self.navigationController = navigationController
        return self
    }

    public func with(parent: ParentCoordinator) -> CoordinatorConfiguration<T> {
        self.parentCoordinator = parent
        return self
    }

    public func create() -> T {
        let scopedContainer = container.createScope()

        if let navController = navigationController {
            scopedContainer.register(UINavigationController.self, scope: .singleton) { _ in
                navController
            }
        }

        let coordinator = scopedContainer.resolve(coordinatorType)

        if let baseCoordinator = coordinator as? BaseCoordinatorImpl,
           let parent = parentCoordinator {
            baseCoordinator.parentCoordinator = parent
        }

        return coordinator
    }
}