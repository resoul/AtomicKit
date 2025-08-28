# AtomicKit

**AtomicKit** — a library for iOS projects that simplifies building architecture with:

- **Coordinators** for navigation management
- **Clean Architecture** with clear separation of layers
- **Dependency Injection** for all components
- **Scoped containers** for dependency isolation
- **Factories** for object creation
- **Type-safe dependency injection**

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/resoul/AtomicKit.git", from: "1.0.0")
]
```

---

## Architecture

### Coordinators
Each feature is managed by its own coordinator.  
Example `AppCoordinator`:

```swift
protocol AppCoordinator: Coordinator {
    func showMainFlow()
    func showAuthFlow()
}

class AppCoordinatorImpl: CoordinatorImpl, AppCoordinator {
    @Injected private var coordinatorFactory: CoordinatorFactory

    override func start() {
        showAuthFlow()
    }

    func showMainFlow() {
        let main: MainCoordinator = coordinatorFactory.createCoordinator(MainCoordinator.self, navigationController: navigationController)
        coordinate(to: main)
    }

    func showAuthFlow() {
        let auth: AuthCoordinator = coordinatorFactory.createCoordinator(AuthCoordinator.self, navigationController: navigationController)
        coordinate(to: auth)
    }
}
```

---

### Dependency Injection
Dependencies are injected using the `@Injected` property wrapper:

```swift
class LoginViewModel {
    @Injected private var userService: UserService
}
```

---

### Scoped containers
Isolate dependencies per feature/module:

```swift
let container = Container.scoped()
container.register(UserService.self) { UserServiceImpl() }
```

---

### Factories
Create objects using factories:

```swift
let loginVC = viewControllerFactory.createViewController(LoginViewController.self)
```

---

## Usage

1. Create a main `AppCoordinator` and launch it in `SceneDelegate`.
2. Define coordinators for each feature (e.g., `AuthCoordinator`, `MainCoordinator`).
3. Register dependencies in the container.
4. Use factories and `@Injected` to obtain objects.

---

## Example App Startup

```swift
let appCoordinator = AppCoordinatorImpl(navigationController: UINavigationController())
appCoordinator.start()
window.rootViewController = appCoordinator.navigationController
window.makeKeyAndVisible()
```

---

## Goal

AtomicKit helps you quickly build **clean, modular, and scalable architecture** without unnecessary boilerplate.

---

## TODO

- add tests