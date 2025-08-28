import Foundation

public protocol Injectable {
    static func inject(container: DIContainer) -> Self
}

public protocol AutoInjectable: Injectable {
    init()
}

extension AutoInjectable {
    public static func inject(container: DIContainer) -> Self {
        return Self()
    }
}