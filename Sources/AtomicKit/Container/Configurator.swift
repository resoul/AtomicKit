import Foundation

public protocol Module {
    func configure(container: Container)
}

public final class Configurator {
    public static func configure(
        modules: [Module] = [],
        container: Container = SafeContainer.shared
    ) {
        modules.forEach { $0.configure(container: container) }
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
