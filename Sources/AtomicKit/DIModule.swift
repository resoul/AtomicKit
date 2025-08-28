import Foundation

public protocol DIModule {
    func configure(container: DIContainer)
}

public protocol ServiceModule: DIModule {}
public protocol DataModule: DIModule {}
public protocol DomainModule: DIModule {}
public protocol PresentationModule: DIModule {}
public protocol CoordinatorModule: DIModule {}

public final class DIConfigurator {
    public static func configure(
        serviceModules: [ServiceModule] = [],
        dataModules: [DataModule] = [],
        domainModules: [DomainModule] = [],
        presentationModules: [PresentationModule] = [],
        coordinatorModules: [CoordinatorModule] = [],
        container: DIContainer = DefaultDIContainer.shared
    ) {
        // Sorting: Services → Data → Domain → Presentation → Coordinators
        serviceModules.forEach { $0.configure(container: container) }
        dataModules.forEach { $0.configure(container: container) }
        domainModules.forEach { $0.configure(container: container) }
        presentationModules.forEach { $0.configure(container: container) }
        coordinatorModules.forEach { $0.configure(container: container) }
    }
}