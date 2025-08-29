# AtomicKit

**AtomicKit** is a comprehensive iOS architecture framework that provides everything you need to build scalable, maintainable, and well-structured iOS applications using modern Swift patterns.

## 🚀 Features

- **🧭 Coordinator Pattern** - Advanced navigation management with event-driven architecture
- **🏗️ Clean Architecture** - Clear separation of concerns across layers
- **💉 Dependency Injection** - Type-safe DI with scoped containers and property wrappers
- **📡 Networking** - Powerful HTTP client with interceptors, retry logic, and progress tracking
- **📝 Logging** - Flexible logging system with multiple destinations and formatters
- **🏭 Factory Pattern** - Simplified object creation and configuration
- **🔄 Reactive Programming** - Built-in Combine support throughout
- **🎯 Type Safety** - Leverages Swift's type system for compile-time guarantees

---

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/resoul/AtomicKit.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'AtomicKit', '~> 1.0'
```

---

## 🏛️ Architecture Overview

AtomicKit promotes a layered architecture with clear boundaries:

```
┌─────────────────────┐
│   Presentation      │ ← ViewControllers, ViewModels, Coordinators
├─────────────────────┤
│     Domain         │ ← Use Cases, Entities, Repository Protocols
├─────────────────────┤
│      Data          │ ← Repository Implementations, Data Sources
├─────────────────────┤
│    Services        │ ← Network, Storage, External APIs
└─────────────────────┘
```

---

## 🧭 Coordinator Pattern

### Basic Coordinator Setup

```swift
// Define your coordinator protocol
protocol AuthCoordinator: Coordinator {
    func showLogin()
    func showSignUp()
    func showMainFlow()
}

// Implement the coordinator
class AuthCoordinatorImpl: CoordinatorImpl, AuthCoordinator {
    @Injected private var coordinatorFactory: CoordinatorFactory
    @Injected private var viewControllerFactory: ViewControllerFactory
    
    override func start() {
        showLogin()
    }
    
    func showLogin() {
        let loginVC = viewControllerFactory.createViewController(LoginViewController.self)
        push(loginVC)
    }
    
    func showSignUp() {
        let signUpVC = viewControllerFactory.createViewController(SignUpViewController.self)
        push(signUpVC)
    }
    
    func showMainFlow() {
        let mainCoordinator = coordinatorFactory.createCoordinator(
            MainCoordinator.self, 
            navigationController: navigationController
        )
        coordinate(to: mainCoordinator)
    }
}
```

### Event-Driven Coordinators

```swift
enum AuthEvent: CoordinatorEvent {
    case loginSuccess
    case signUpRequested
    case forgotPasswordRequested
}

class AuthCoordinatorImpl: EnhancedCoordinatorImpl<AuthEvent>, AuthCoordinator {
    override func handle(event: AuthEvent) {
        switch event {
        case .loginSuccess:
            showMainFlow()
        case .signUpRequested:
            showSignUp()
        case .forgotPasswordRequested:
            showForgotPassword()
        }
    }
}

// In your ViewController
class LoginViewController: UIViewController {
    @WeakCoordinator var coordinator: AuthCoordinator?
    
    @IBAction func loginButtonTapped() {
        // Perform login logic
        if let eventCoordinator = coordinator as? EnhancedCoordinatorImpl<AuthEvent> {
            eventCoordinator.send(event: .loginSuccess)
        }
    }
}
```

### Flow Coordinators with Results

```swift
typealias OnboardingResult = Result<User, OnboardingError>

class OnboardingCoordinator: BaseFlowCoordinator<OnboardingResult> {
    override func start() {
        showWelcome()
    }
    
    private func showWelcome() {
        let welcomeVC = viewControllerFactory.createViewController(WelcomeViewController.self)
        push(welcomeVC)
    }
    
    func handleOnboardingComplete(user: User) {
        completeFlow(with: .success(user))
    }
}

// Usage in parent coordinator
func startOnboarding() {
    let onboardingCoordinator = coordinatorFactory.createCoordinator(
        OnboardingCoordinator.self,
        navigationController: navigationController
    )
    
    onboardingCoordinator.flowCompletion = { [weak self] result in
        switch result {
        case .success(let user):
            self?.showMainFlow(for: user)
        case .failure(let error):
            self?.showError(error)
        }
    }
    
    coordinate(to: onboardingCoordinator)
}
```

---

## 💉 Dependency Injection

### Container Setup

```swift
// Configure your dependencies
let container = SafeContainer.shared

// Register services
container.register(UserService.self, scope: .singleton) { container in
    UserServiceImpl(repository: container.resolve(UserRepository.self))
}

container.register(UserRepository.self, scope: .singleton) { container in
    UserRepositoryImpl(networkService: container.resolve(NetworkService.self))
}

// Register coordinators
container.register(AuthCoordinator.self, scope: .transient) { container in
    AuthCoordinatorImpl(
        navigationController: container.resolve(UINavigationController.self),
        container: container
    )
}
```

### Using Modules for Organization

```swift
struct AuthModule: PresentationModule {
    func configure(container: Container) {
        // View Controllers
        container.registerTransient(LoginViewController.self) { container in
            let vc = LoginViewController()
            vc.viewModel = container.resolve(LoginViewModel.self)
            return vc
        }
        
        // View Models
        container.registerTransient(LoginViewModel.self) { container in
            LoginViewModel(
                loginUseCase: container.resolve(LoginUseCase.self),
                validator: container.resolve(FormValidator.self)
            )
        }
        
        // Coordinators
        container.registerTransient(AuthCoordinator.self) { container in
            AuthCoordinatorImpl(
                navigationController: container.resolve(UINavigationController.self),
                container: container
            )
        }
    }
}

struct AuthDomainModule: DomainModule {
    func configure(container: Container) {
        container.registerTransient(LoginUseCase.self) { container in
            LoginUseCaseImpl(repository: container.resolve(UserRepository.self))
        }
    }
}

// Configure all modules
Configurator.configure(
    domains: [AuthDomainModule()],
    presentation: [AuthModule()],
    container: SafeContainer.shared
)
```

### Property Wrappers for Clean Injection

```swift
class LoginViewModel: ViewModel {
    @UseCaseInjected private var loginUseCase: LoginUseCase
    @RepositoryInjected private var userRepository: UserRepository
    @LoggerInjected private var logger: Logger
    
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        logger.info("Attempting login", metadata: ["email": email])
        
        return loginUseCase.execute(email: email, password: password)
            .handleEvents(
                receiveOutput: { [weak self] user in
                    self?.logger.info("Login successful", metadata: ["userId": user.id])
                },
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.error("Login failed", metadata: ["error": error.localizedDescription])
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}
```

---

## 📡 Networking

### HTTP Client Configuration

```swift
let networkConfig = NetworkConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    timeout: 30.0,
    retryCount: 3,
    defaultHeaders: [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ],
    requestInterceptors: [
        AuthenticationInterceptor(authType: .bearer("your-token")),
        LoggingInterceptor(logLevel: .debug, logHeaders: true, logBody: false),
        RateLimitingInterceptor(maxRequestsPerSecond: 10)
    ],
    responseInterceptors: [
        RetryInterceptor(maxRetries: 3),
        CachingInterceptor()
    ],
    enableLogging: true
)

let httpClient = URLSessionHTTPClient(
    session: .shared,
    configuration: networkConfig
)
```

### Service Implementation

```swift
protocol UserNetworkService: NetworkService {
    func getUser(id: String) -> AnyPublisher<User, NetworkError>
    func updateUser(_ user: User) -> AnyPublisher<User, NetworkError>
    func uploadAvatar(data: Data) -> AnyPublisher<URL, NetworkError>
}

class UserNetworkServiceImpl: UserNetworkService {
    let baseURL = URL(string: "https://api.example.com")!
    let defaultHeaders = ["Authorization": "Bearer \(token)"]
    let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func getUser(id: String) -> AnyPublisher<User, NetworkError> {
        let request = requestBuilder()
            .path("/users/\(id)")
            .method(.GET)
            .build()
            
        return httpClient.execute(request, responseType: User.self)
    }
    
    func updateUser(_ user: User) -> AnyPublisher<User, NetworkError> {
        let request = requestBuilder()
            .path("/users/\(user.id)")
            .method(.PUT)
            .body(user)
            .build()
            
        return httpClient.execute(request, responseType: User.self)
    }
    
    func uploadAvatar(data: Data) -> AnyPublisher<URL, NetworkError> {
        let formData = MultipartFormDataBuilder()
            .addFileField("avatar", data: data, fileName: "avatar.jpg", mimeType: "image/jpeg")
            .build()
            
        let request = requestBuilder()
            .path("/users/avatar")
            .method(.POST)
            .body(formData.data, encoding: .custom(formData.contentType))
            .build()
            
        return httpClient.execute(request)
            .tryMap { response in
                // Parse upload response to get avatar URL
                let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: response.data)
                return uploadResponse.url
            }
            .mapError { NetworkError.decodingError($0) }
            .eraseToAnyPublisher()
    }
}
```

### Request Building with Pagination

```swift
extension UserNetworkService {
    func getUsers(page: Int = 1, limit: Int = 20) -> AnyPublisher<PaginatedResponse<User>, NetworkError> {
        let request = requestBuilder()
            .path("/users")
            .method(.GET)
            .query("page", page)
            .query("limit", limit)
            .query("sort", "created_at")
            .header("Accept", "application/json")
            .cachePolicy(.returnCacheDataElseLoad)
            .build()
            
        return httpClient.execute(request, responseType: PaginatedResponse<User>.self)
    }
}
```

---

## 📝 Logging

### Logger Configuration

```swift
// Setup composite logger with multiple destinations
let fileLogger = FileLogger(
    minimumLevel: .info,
    category: "App",
    maxFileSize: 10 * 1024 * 1024, // 10MB
    maxBackupCount: 5
)

let consoleLogger = ConsoleLogger(
    minimumLevel: .debug,
    category: "App",
    formatter: CompactLogFormatter()
)

let osLogger = OSLogger(
    minimumLevel: .warning,
    category: "App",
    subsystem: "com.yourapp.ios"
)

AtomicLogger.shared = CompositeLogger(
    loggers: [consoleLogger, fileLogger, osLogger],
    minimumLevel: .debug
)

// Set up logger for specific components
SafeContainer.setLogger(AtomicLogger.shared)
CoordinatorImpl.setLogger(AtomicLogger.shared)
```

### Categorized Logging

```swift
class NetworkManager {
    private let logger = CategorizedLogger(category: "Network")
    
    func performRequest() {
        logger.info("Starting request", metadata: [
            "url": "https://api.example.com/users",
            "method": "GET"
        ])
        
        // ... request logic ...
        
        logger.debug("Request completed", metadata: [
            "statusCode": 200,
            "duration": "1.234s"
        ])
    }
}
```

### Structured Logging

```swift
// JSON formatted logging
let jsonLogger = FileLogger(
    formatter: JSONLogFormatter(),
    fileURL: documentsURL.appendingPathComponent("app.jsonl")
)

// Custom log levels and metadata
logger.warning("User session expired", metadata: [
    "userId": user.id,
    "sessionDuration": sessionDuration,
    "lastActivity": lastActivityTimestamp,
    "context": "background_refresh"
])
```

---

## 🏗️ Clean Architecture Example

### Complete Feature Implementation

```swift
// MARK: - Domain Layer
protocol LoginUseCase: UseCase {
    func execute(email: String, password: String) -> AnyPublisher<User, LoginError>
}

class LoginUseCaseImpl: LoginUseCase {
    @RepositoryInjected private var userRepository: UserRepository
    @RepositoryInjected private var sessionRepository: SessionRepository
    
    func execute(email: String, password: String) -> AnyPublisher<User, LoginError> {
        return userRepository.authenticate(email: email, password: password)
            .flatMap { [weak self] user in
                guard let self = self else {
                    return Fail(error: LoginError.cancelled).eraseToAnyPublisher()
                }
                
                return self.sessionRepository.createSession(for: user)
                    .map { _ in user }
                    .mapError { _ in LoginError.sessionCreationFailed }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Data Layer
class UserRepositoryImpl: UserRepository {
    @Injected private var networkService: UserNetworkService
    @Injected private var cacheService: CacheService
    @LoggerInjected private var logger: Logger
    
    func authenticate(email: String, password: String) -> AnyPublisher<User, LoginError> {
        let credentials = LoginCredentials(email: email, password: password)
        
        return networkService.login(credentials)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.cacheService.store(user, forKey: "current_user")
                self?.logger.info("User authenticated successfully")
            })
            .mapError { networkError in
                self.logger.error("Authentication failed", metadata: ["error": networkError.localizedDescription])
                return LoginError.invalidCredentials
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Presentation Layer
class LoginViewModel: ViewModel {
    @UseCaseInjected private var loginUseCase: LoginUseCase
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                !email.isEmpty && password.count >= 6
            }
            .eraseToAnyPublisher()
    }
    
    func login() {
        isLoading = true
        errorMessage = nil
        
        loginUseCase.execute(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    // Login successful - coordinator will handle navigation
                    NotificationCenter.default.post(name: .userDidLogin, object: user)
                }
            )
            .store(in: &cancellables)
    }
}
```

---

## 🚀 App Startup

### SceneDelegate Setup

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // Configure dependencies
        configureDependencies()
        
        // Setup window and coordinator
        window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()
        
        appCoordinator = SafeContainer.shared.resolve(AppCoordinator.self)
        if let coordinator = appCoordinator as? AppCoordinatorImpl {
            coordinator.navigationController = navigationController
        }
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        appCoordinator?.start()
    }
    
    private func configureDependencies() {
        Configurator.configure(
            services: [NetworkModule(), CacheModule()],
            data: [AuthDataModule(), UserDataModule()],
            domains: [AuthDomainModule(), UserDomainModule()],
            presentation: [AuthModule(), UserModule()],
            coordinators: [CoordinatorModule()]
        )
    }
}
```

### App Coordinator

```swift
enum AppEvent: CoordinatorEvent {
    case userDidLogin(User)
    case userDidLogout
    case onboardingRequired
}

class AppCoordinatorImpl: EnhancedCoordinatorImpl<AppEvent>, AppCoordinator {
    @Injected private var sessionService: SessionService
    @Injected private var coordinatorFactory: CoordinatorFactory
    
    override func start() {
        if sessionService.hasValidSession {
            showMainFlow()
        } else {
            showAuthFlow()
        }
        
        setupEventHandling()
    }
    
    private func setupEventHandling() {
        NotificationCenter.default.publisher(for: .userDidLogin)
            .compactMap { $0.object as? User }
            .sink { [weak self] user in
                self?.send(event: .userDidLogin(user))
            }
            .store(in: &cancellables)
    }
    
    override func handle(event: AppEvent) {
        switch event {
        case .userDidLogin(let user):
            showMainFlow()
        case .userDidLogout:
            showAuthFlow()
        case .onboardingRequired:
            showOnboarding()
        }
    }
    
    func showMainFlow() {
        let mainCoordinator = coordinatorFactory.createCoordinator(
            MainCoordinator.self, 
            navigationController: navigationController
        )
        coordinate(to: mainCoordinator)
    }
    
    func showAuthFlow() {
        let authCoordinator = coordinatorFactory.createCoordinator(
            AuthCoordinator.self, 
            navigationController: navigationController
        )
        coordinate(to: authCoordinator)
    }
}
```

---

## 🧪 Testing

### Unit Testing with Mocks

```swift
class MockUserRepository: UserRepository {
    var authenticateResult: Result<User, LoginError> = .failure(.invalidCredentials)
    
    func authenticate(email: String, password: String) -> AnyPublisher<User, LoginError> {
        return authenticateResult.publisher.eraseToAnyPublisher()
    }
}

class LoginUseCaseTests: XCTestCase {
    private var useCase: LoginUseCase!
    private var mockRepository: MockUserRepository!
    private var container: Container!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        container = SafeContainer()
        mockRepository = MockUserRepository()
        cancellables = Set<AnyCancellable>()
        
        container.register(UserRepository.self) { _ in self.mockRepository }
        useCase = LoginUseCaseImpl()
    }
    
    func testLoginSuccess() {
        // Given
        let expectedUser = User(id: "123", email: "test@example.com")
        mockRepository.authenticateResult = .success(expectedUser)
        
        let expectation = XCTestExpectation(description: "Login should succeed")
        
        // When
        useCase.execute(email: "test@example.com", password: "password123")
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Login should not fail")
                    }
                },
                receiveValue: { user in
                    // Then
                    XCTAssertEqual(user.id, expectedUser.id)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
```

---

## 📚 Advanced Features

### Custom Property Wrappers

```swift
@propertyWrapper
struct UserDefaultsInjected<T: Codable> {
    private let key: String
    private let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let value = try? JSONDecoder().decode(T.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// Usage
class SettingsManager {
    @UserDefaultsInjected("user_preferences", defaultValue: UserPreferences())
    var userPreferences: UserPreferences
}
```

### Memory Logger for Testing

```swift
class APIServiceTests: XCTestCase {
    private var memoryLogger: MemoryLogger!
    
    override func setUp() {
        super.setUp()
        memoryLogger = MemoryLogger()
        AtomicLogger.shared = memoryLogger
    }
    
    func testAPICallLogging() {
        // Perform API call
        apiService.fetchData()
        
        // Verify logging
        let networkEntries = memoryLogger.entries(containing: "Network")
        XCTAssertFalse(networkEntries.isEmpty)
        
        let errorEntries = memoryLogger.entries(for: .error)
        XCTAssertTrue(errorEntries.isEmpty)
    }
}
```

---

## 📖 Best Practices

### 1. Coordinator Organization
```swift
// Group related coordinators
protocol TabBarCoordinator: Coordinator {
    func selectTab(_ index: Int)
}

// Use specific coordinator protocols
protocol ProductDetailCoordinator: Coordinator {
    func showProduct(_ product: Product)
    func showReviews(for product: Product)
    func showPurchaseFlow(for product: Product)
}
```

### 2. Service Layer Pattern
```swift
// Keep services focused and single-purpose
protocol NotificationService: Service {
    func requestPermission() -> AnyPublisher<Bool, Never>
    func schedule(_ notification: LocalNotification) -> AnyPublisher<Void, Error>
    func cancelAll()
}

// Use composition for complex services
class UserManager {
    @Injected private var userService: UserService
    @Injected private var sessionService: SessionService
    @Injected private var cacheService: CacheService
    @LoggerInjected private var logger: Logger
}
```

### 3. Error Handling
```swift
// Define domain-specific errors
enum UserError: Error, LocalizedError {
    case notFound
    case insufficientPermissions
    case profileIncomplete
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "User not found"
        case .insufficientPermissions:
            return "Insufficient permissions"
        case .profileIncomplete:
            return "Please complete your profile"
        }
    }
}
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

---

## 📄 License

AtomicKit is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

---

## 🙏 Acknowledgments

- Inspired by clean architecture principles
- Built with modern Swift and Combine
- Designed for iOS 13+ and Swift 5.5+