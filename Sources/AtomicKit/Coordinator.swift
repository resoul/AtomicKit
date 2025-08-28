import UIKit

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
