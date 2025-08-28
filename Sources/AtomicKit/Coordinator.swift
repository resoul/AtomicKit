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
        if let baseCoordinator = coordinator as? CoordinatorImpl {
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

        let coordinator = scopedContainer.resolve(coordinatorType)

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

// MARK: - Event System
public protocol CoordinatorEvent {}

public protocol EventDrivenCoordinator: Coordinator {
    associatedtype Event: CoordinatorEvent
    var eventPublisher: AnyPublisher<Event, Never> { get }
    func handle(event: Event)
}

// MARK: - Result Handling
public protocol ResultCoordinator: Coordinator {
    associatedtype Result
    var resultPublisher: AnyPublisher<Result, Never> { get }
}

// MARK: - Enhanced Base Coordinator
open class EnhancedCoordinatorImpl<Event: CoordinatorEvent>: CoordinatorImpl, EventDrivenCoordinator {
    private let eventSubject = PassthroughSubject<Event, Never>()
    public var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    public override init(navigationController: UINavigationController, container: Container) {
        super.init(navigationController: navigationController, container: container)
        setupEventHandling()
    }

    private func setupEventHandling() {
        eventPublisher
            .sink { [weak self] event in
                self?.handle(event: event)
            }
            .store(in: &cancellables)
    }

    open func handle(event: Event) {
        // Override in subclasses
    }

    public func send(event: Event) {
        eventSubject.send(event)
    }

    // MARK: - Enhanced Navigation
    public func pushWithResult<T>(_ viewController: UIViewController, animated: Bool = true) -> AnyPublisher<T, Never> where T: Any {
        let resultSubject = PassthroughSubject<T, Never>()

        if let resultProvider = viewController as? ResultProvider<T> {
            resultProvider.resultPublisher
                .sink { result in
                    resultSubject.send(result)
                }
                .store(in: &cancellables)
        }

        push(viewController, animated: animated)
        return resultSubject.eraseToAnyPublisher()
    }

    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Result Provider Protocol
public protocol ResultProvider<T> {
    associatedtype T
    var resultPublisher: AnyPublisher<T, Never> { get }
}

// MARK: - Flow Coordinator
public protocol FlowCoordinator: Coordinator {
    associatedtype FlowResult
    var flowCompletion: ((FlowResult) -> Void)? { get set }

    func completeFlow(with result: FlowResult)
}

open class BaseFlowCoordinator<FlowResult>: EnhancedCoordinatorImpl<CoordinatorEvent>, FlowCoordinator {
    public var flowCompletion: ((FlowResult) -> Void)?

    public func completeFlow(with result: FlowResult) {
        flowCompletion?(result)
        parentCoordinator?.childDidFinish(self)
    }
}

// MARK: - Coordinator States
public enum CoordinatorState {
    case idle
    case starting
    case active
    case finishing
    case finished
}

public protocol StatefulCoordinator: Coordinator {
    var state: CoordinatorState { get }
    var statePublisher: AnyPublisher<CoordinatorState, Never> { get }
}

// MARK: - Navigation Stack Management
public protocol StackCoordinator: Coordinator {
    func popToCoordinator<T: Coordinator>(_ coordinatorType: T.Type, animated: Bool)
    func popToViewController<T: UIViewController>(_ viewControllerType: T.Type, animated: Bool)
}

extension CoordinatorImpl: StackCoordinator {
    public func popToCoordinator<T: Coordinator>(_ coordinatorType: T.Type, animated: Bool = true) {
        // Find the coordinator in child stack and pop to its root view controller
        if let coordinator = childCoordinators.first(where: { $0 is T }) as? CoordinatorImpl {
            if let rootVC = coordinator.navigationController.viewControllers.first {
                navigationController.popToViewController(rootVC, animated: animated)
            }
        }
    }

    public func popToViewController<T: UIViewController>(_ viewControllerType: T.Type, animated: Bool = true) {
        if let targetVC = navigationController.viewControllers.first(where: { $0 is T }) {
            navigationController.popToViewController(targetVC, animated: animated)
        }
    }
}

// MARK: - Tab Coordinator
open class TabCoordinator: CoordinatorImpl {
    private let tabBarController: UITabBarController

    public init(tabBarController: UITabBarController, container: Container) {
        self.tabBarController = tabBarController
        super.init(navigationController: UINavigationController(), container: container)
    }

    public func addTab<T: Coordinator>(_ coordinatorType: T.Type, title: String, image: UIImage? = nil) {
        let navController = UINavigationController()
        let coordinator = container.resolve(coordinatorType)

        if let baseCoordinator = coordinator as? CoordinatorImpl {
            baseCoordinator.parentCoordinator = self
        }

        navController.tabBarItem = UITabBarItem(title: title, image: image, tag: childCoordinators.count)

        childCoordinators.append(coordinator)
        coordinator.start()

        var controllers = tabBarController.viewControllers ?? []
        controllers.append(navController)
        tabBarController.setViewControllers(controllers, animated: false)
    }
}

// MARK: - Modal Coordinator
public protocol ModalCoordinator: Coordinator {
    func presentModally(from presenter: UIViewController, animated: Bool, completion: (() -> Void)?)
    func dismissModal(animated: Bool, completion: (() -> Void)?)
}

open class BaseModalCoordinator: CoordinatorImpl, ModalCoordinator {
    private weak var presenter: UIViewController?

    public func presentModally(from presenter: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        self.presenter = presenter
        presenter.present(navigationController, animated: animated, completion: completion)
    }

    public func dismissModal(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController.dismiss(animated: animated, completion: completion)
        parentCoordinator?.childDidFinish(self)
    }
}