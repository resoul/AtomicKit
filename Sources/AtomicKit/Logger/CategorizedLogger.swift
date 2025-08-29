import Foundation

public struct CategorizedLogger {
    private let baseLogger: Logger
    private let category: String

    public init(logger: Logger = AtomicLogger.shared, category: String) {
        self.baseLogger = logger
        self.category = category
    }

    public func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        var categoryLogger = baseLogger
        categoryLogger.category = category
        categoryLogger.verbose(message, file: file, function: function, line: line, metadata: metadata)
    }

    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        var categoryLogger = baseLogger
        categoryLogger.category = category
        categoryLogger.debug(message, file: file, function: function, line: line, metadata: metadata)
    }

    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        var categoryLogger = baseLogger
        categoryLogger.category = category
        categoryLogger.info(message, file: file, function: function, line: line, metadata: metadata)
    }

    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        var categoryLogger = baseLogger
        categoryLogger.category = category
        categoryLogger.warning(message, file: file, function: function, line: line, metadata: metadata)
    }

    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        var categoryLogger = baseLogger
        categoryLogger.category = category
        categoryLogger.error(message, file: file, function: function, line: line, metadata: metadata)
    }

    public func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        var categoryLogger = baseLogger
        categoryLogger.category = category
        categoryLogger.critical(message, file: file, function: function, line: line, metadata: metadata)
    }
}