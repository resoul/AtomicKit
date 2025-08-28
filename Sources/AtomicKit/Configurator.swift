import Foundation

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
        container: Container = DefaultContainer.shared
    ) {
        // Sorting: Services → Data → Domain → Presentation → Coordinators
        services.forEach { $0.configure(container: container) }
        data.forEach { $0.configure(container: container) }
        domains.forEach { $0.configure(container: container) }
        presentation.forEach { $0.configure(container: container) }
        coordinators.forEach { $0.configure(container: container) }
    }
}
