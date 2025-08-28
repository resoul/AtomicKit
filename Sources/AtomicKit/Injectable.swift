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
