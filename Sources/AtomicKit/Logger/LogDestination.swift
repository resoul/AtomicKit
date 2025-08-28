import Foundation

public protocol LogDestination {
    func write(_ formattedMessage: String)
    func flush()
}

public class ConsoleDestination: LogDestination {
    public init() {}

    public func write(_ formattedMessage: String) {
        print(formattedMessage)
    }

    public func flush() {
        // Console doesn't need flushing
    }
}