import Foundation

public protocol Logger: AnyObject {
    var minimumLevel: LogLevel { get set }
    var category: String? { get set }

    func log(_ entry: LogEntry)
    func log(
        level: LogLevel,
        message: String,
        file: String,
        function: String,
        line: Int,
        metadata: [String: Any]
    )
}

extension Logger {
    public func log(
        level: LogLevel,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: Any] = [:]
    ) {
        guard level >= minimumLevel else { return }

        let entry = LogEntry(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line,
            metadata: metadata,
            category: category
        )

        log(entry)
    }

    // Convenience methods
    public func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        log(level: .verbose, message: message, file: file, function: function, line: line, metadata: metadata)
    }

    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        log(level: .debug, message: message, file: file, function: function, line: line, metadata: metadata)
    }

    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        log(level: .info, message: message, file: file, function: function, line: line, metadata: metadata)
    }

    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        log(level: .warning, message: message, file: file, function: function, line: line, metadata: metadata)
    }

    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        log(level: .error, message: message, file: file, function: function, line: line, metadata: metadata)
    }

    public func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        log(level: .critical, message: message, file: file, function: function, line: line, metadata: metadata)
    }
}
