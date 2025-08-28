import UIKit
import Foundation

// MARK: - Base Protocols
public protocol UseCase {}
public protocol Repository {}
public protocol DataSource {}
public protocol Service {}
public protocol ViewModel: AnyObject {}
public protocol Coordinator: AnyObject {}

// MARK: - Coordinator Protocols
public protocol BaseCoordinator: Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get }

    func start()
    func coordinate(to coordinator: Coordinator)
    func removeChild(_ coordinator: Coordinator)
}

public protocol ParentCoordinator: BaseCoordinator {
    func childDidFinish(_ child: Coordinator)
}

// MARK: - Navigation
public protocol NavigationCoordinator: BaseCoordinator {
    func push(_ viewController: UIViewController, animated: Bool)
    func pop(animated: Bool)
    func popToRoot(animated: Bool)
    func present(_ viewController: UIViewController, animated: Bool)
    func dismiss(animated: Bool)
}

// MARK: - Lifecycle
public protocol Injectable {
    static func create(container: DIContainer) -> Self
}

public protocol Disposable {
    func dispose()
}

// MARK: - Scopes
public enum DIScope {
    case singleton
    case transient
    case scoped
}