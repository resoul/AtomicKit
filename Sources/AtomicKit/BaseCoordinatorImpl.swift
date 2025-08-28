import UIKit

open class BaseCoordinatorImpl: NSObject, NavigationCoordinator, ParentCoordinator {
    public var childCoordinators: [Coordinator] = []
    public let navigationController: UINavigationController
    public let container: Container
    public weak var parentCoordinator: ParentCoordinator?

    public init(navigationController: UINavigationController, container: Container) {
        self.navigationController = navigationController
        self.container = container
        super.init()
    }

    open func start() {
        fatalError("Start method must be implemented")
    }

    public func coordinate(to coordinator: Coordinator) {
        childCoordinators.append(coordinator)
        if let baseCoordinator = coordinator as? BaseCoordinatorImpl {
            baseCoordinator.parentCoordinator = self
        }
        coordinator.start()
    }

    public func removeChild(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }

    public func childDidFinish(_ child: Coordinator) {
        removeChild(child)
    }

    // MARK: - Navigation Methods
    public func push(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.pushViewController(viewController, animated: animated)
    }

    public func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }

    public func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }

    public func present(_ viewController: UIViewController, animated: Bool = true) {
        navigationController.present(viewController, animated: animated)
    }

    public func dismiss(animated: Bool = true) {
        navigationController.dismiss(animated: animated)
    }
}