import UIKit
import Combine

// MARK: - Coordinator Protocols
public protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get }

    func start()
    func coordinate(to coordinator: Coordinator)
    func removeChild(_ coordinator: Coordinator)
}

public protocol ParentCoordinator: Coordinator {
    func childDidFinish(_ child: Coordinator)
}

// MARK: - Navigation
public protocol NavigationCoordinator: Coordinator {
    func push(_ viewController: UIViewController, animated: Bool)
    func pop(animated: Bool)
    func popToRoot(animated: Bool)
    func present(_ viewController: UIViewController, animated: Bool)
    func dismiss(animated: Bool)
}

open class CoordinatorImpl: NSObject, NavigationCoordinator, ParentCoordinator {
    public var childCoordinators: [Coordinator] = []
    public let navigationController: UINavigationController
    public let container: Container
    public weak var parentCoordinator: ParentCoordinator?

    private static var logger: Logger?

    public init(navigationController: UINavigationController, container: Container) {
        self.navigationController = navigationController
        self.container = container
        super.init()
    }

    public static func setLogger(_ logger: Logger) {
        self.logger = logger
    }

    open func start() {
        logCoordinatorOperation("Starting coordinator: \(type(of: self))", metadata: [
            "coordinator": String(describing: type(of: self))
        ])
    }

    public func coordinate(to coordinator: Coordinator) {
        logCoordinatorOperation("Coordinating to: \(type(of: coordinator))", metadata: [
            "from": String(describing: type(of: self)),
            "to": String(describing: type(of: coordinator))
        ])
        childCoordinators.append(coordinator)
        if let baseCoordinator = coordinator as? CoordinatorImpl {
            baseCoordinator.parentCoordinator = self
        }
        coordinator.start()
    }

    public func removeChild(_ coordinator: Coordinator) {
        logCoordinatorOperation("Removing child coordinator: \(type(of: coordinator))", metadata: [
            "parent": String(describing: type(of: self)),
            "child": String(describing: type(of: coordinator))
        ])
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }

    public func childDidFinish(_ child: Coordinator) {
        removeChild(child)
    }

    // MARK: - Navigation Methods
    public func push(_ viewController: UIViewController, animated: Bool = true) {
        logCoordinatorOperation("Pushing view controller: \(type(of: viewController))", metadata: [
            "coordinator": String(describing: type(of: self)),
            "viewController": String(describing: type(of: viewController)),
            "animated": animated
        ])
        navigationController.pushViewController(viewController, animated: animated)
    }

    public func pop(animated: Bool = true) {
        logCoordinatorOperation("Popping view controller", metadata: [
            "coordinator": String(describing: type(of: self)),
            "animated": animated
        ])
        navigationController.popViewController(animated: animated)
    }

    public func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }

    public func present(_ viewController: UIViewController, animated: Bool = true) {
        logCoordinatorOperation("Presenting view controller: \(type(of: viewController))", metadata: [
            "coordinator": String(describing: type(of: self)),
            "viewController": String(describing: type(of: viewController)),
            "animated": animated
        ])
        navigationController.present(viewController, animated: animated)
    }

    public func dismiss(animated: Bool = true) {
        logCoordinatorOperation("Dismissing view controller", metadata: [
            "coordinator": String(describing: type(of: self)),
            "animated": animated
        ])
        navigationController.dismiss(animated: animated)
    }

    private func logCoordinatorOperation(_ message: String, level: LogLevel = .debug, metadata: [String: Any] = [:]) {
        Self.logger?.log(level: level, message: message, metadata: metadata)
    }
}

public final class CoordinatorBuilder {
    private let container: Container

    public init(container: Container = SafeContainer.shared) {
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

        let coordinator = scopedContainer.resolve(coordinatorType) as T

        if let baseCoordinator = coordinator as? CoordinatorImpl,
           let parent = parentCoordinator {
            baseCoordinator.parentCoordinator = parent
        }

        return coordinator
    }
}

public protocol CoordinatorFactory {
    func createCoordinator<T: Coordinator>(_ type: T.Type, navigationController: UINavigationController) -> T
    func createCoordinator<T: Coordinator>(_ type: T.Type) -> T
}

public final class DefaultCoordinatorFactory: CoordinatorFactory {
    private let container: Container

    public init(container: Container = SafeContainer.shared) {
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
