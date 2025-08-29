import Foundation
import UIKit

public protocol ViewModelFactory {
    func createViewModel<T: ViewModel>(_ type: T.Type) -> T
}

public final class DefaultViewModelFactory: ViewModelFactory {
    private let container: Container

    public init(container: Container = SafeContainer.shared) {
        self.container = container
    }

    public func createViewModel<T: ViewModel>(_ type: T.Type) -> T {
        return container.resolve(type)
    }
}

public protocol UseCaseFactory {
    func createUseCase<T: UseCase>(_ type: T.Type) -> T
}

public final class DefaultUseCaseFactory: UseCaseFactory {
    private let container: Container

    public init(container: Container = SafeContainer.shared) {
        self.container = container
    }

    public func createUseCase<T: UseCase>(_ type: T.Type) -> T {
        return container.resolve(type)
    }
}

public protocol ViewControllerFactory {
    func createViewController<T: UIViewController>(_ type: T.Type) -> T
}

public final class DefaultViewControllerFactory: ViewControllerFactory {
    private let container: Container

    public init(container: Container = SafeContainer.shared) {
        self.container = container
    }

    public func createViewController<T: UIViewController>(_ type: T.Type) -> T {
        return container.resolve(type)
    }
}
