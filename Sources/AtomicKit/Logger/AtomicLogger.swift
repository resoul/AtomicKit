import Foundation

public final class AtomicLogger {
    public static var shared: Logger = ConsoleLogger(minimumLevel: .info)

    private init() {}

    // Global convenience methods
    public static func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        shared.verbose(message, file: file, function: function, line: line, metadata: metadata)
    }

    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        shared.debug(message, file: file, function: function, line: line, metadata: metadata)
    }

    public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        shared.info(message, file: file, function: function, line: line, metadata: metadata)
    }

    public static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        shared.warning(message, file: file, function: function, line: line, metadata: metadata)
    }

    public static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        shared.error(message, file: file, function: function, line: line, metadata: metadata)
    }

    public static func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line, metadata: [String: Any] = [:]) {
        shared.critical(message, file: file, function: function, line: line, metadata: metadata)
    }
}