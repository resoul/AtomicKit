import Foundation

public protocol Injectable {
    static func create(container: Container) -> Self
}

public protocol AutoInjectable: Injectable {
    init()
}

extension AutoInjectable {
    public static func inject(container: Container) -> Self {
        return Self()
    }
}

public protocol Module {
    func configure(container: Container)
}

public protocol ServiceModule: Module {}
public protocol DataModule: Module {}
public protocol DomainModule: Module {}
public protocol PresentationModule: Module {}
public protocol CoordinatorModule: Module {}

public final class Configurator {
    public static func configure(
        services: [ServiceModule] = [],
        data: [DataModule] = [],
        domains: [DomainModule] = [],
        presentation: [PresentationModule] = [],
        coordinators: [CoordinatorModule] = [],
        container: Container = SafeContainer.shared
    ) {
        // Sorting: Services → Data → Domain → Presentation → Coordinators
        services.forEach { $0.configure(container: container) }
        data.forEach { $0.configure(container: container) }
        domains.forEach { $0.configure(container: container) }
        presentation.forEach { $0.configure(container: container) }
        coordinators.forEach { $0.configure(container: container) }
    }
}

@resultBuilder
public struct ModuleBuilder {
    public static func buildBlock(_ modules: Module...) -> [Module] {
        return modules
    }
}

public extension Configurator {
    static func configure(container: Container = SafeContainer.shared, @ModuleBuilder _ builder: () -> [Module]) {
        let modules = builder()
        modules.forEach { $0.configure(container: container) }
    }
}