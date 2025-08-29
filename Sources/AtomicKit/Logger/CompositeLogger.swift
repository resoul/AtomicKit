import Foundation

public final class CompositeLogger: Logger {
    public var minimumLevel: LogLevel {
        didSet {
            for logger in loggers {
                logger.minimumLevel = minimumLevel
            }
        }
    }

    public var category: String? {
        didSet {
            for logger in loggers {
                logger.category = category
            }
        }
    }

    private var loggers: [Logger]

    public init(loggers: [Logger], minimumLevel: LogLevel = .info, category: String? = nil) {
        self.loggers = loggers
        self.minimumLevel = minimumLevel
        self.category = category

        // Sync initial values
        for logger in self.loggers {
            logger.minimumLevel = minimumLevel
            logger.category = category
        }
    }

    public func log(_ entry: LogEntry) {
        for logger in loggers {
            logger.log(entry)
        }
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
