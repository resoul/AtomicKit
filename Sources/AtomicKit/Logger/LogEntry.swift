import Foundation

public struct LogEntry {
    public let level: LogLevel
    public let message: String
    public let timestamp: Date
    public let file: String
    public let function: String
    public let line: Int
    public let metadata: [String: Any]
    public let category: String?

    public init(
        level: LogLevel,
        message: String,
        timestamp: Date = Date(),
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: Any] = [:],
        category: String? = nil
    ) {
        self.level = level
        self.message = message
        self.timestamp = timestamp
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
        self.category = category
    }

    public var fileName: String {
        return (file as NSString).lastPathComponent
    }

    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}