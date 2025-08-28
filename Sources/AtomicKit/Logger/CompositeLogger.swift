import Foundation
import os.log

public final class CompositeLogger: Logger {
    public var minimumLevel: LogLevel {
        didSet {
            loggers.forEach { $0.minimumLevel = minimumLevel }
        }
    }

    public var category: String? {
        didSet {
            loggers.forEach { $0.category = category }
        }
    }

    private var loggers: [Logger]

    public init(loggers: [Logger], minimumLevel: LogLevel = .info, category: String? = nil) {
        self.loggers = loggers
        self.minimumLevel = minimumLevel
        self.category = category

        // Sync initial values
        self.loggers.forEach { logger in
            logger.minimumLevel = minimumLevel
            logger.category = category
        }
    }

    public func log(_ entry: LogEntry) {
        loggers.forEach { $0.log(entry) }
    }

    public func addLogger(_ logger: Logger) {
        logger.minimumLevel = minimumLevel
        logger.category = category
        loggers.append(logger)
    }

    public func removeLogger(_ logger: Logger) {
        loggers.removeAll { $0 === logger }
    }
}
