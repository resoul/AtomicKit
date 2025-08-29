import Foundation
import os.log

public final class SilentLogger: Logger {
    public var minimumLevel: LogLevel = .critical
    public var category: String?

    public init() {}

    public func log(_ entry: LogEntry) {
        // Do nothing
    }
}