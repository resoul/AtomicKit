import Foundation

public struct JSONLogFormatter: LogFormatter {
    public init() {}

    public func format(_ entry: LogEntry) -> String {
        var json: [String: Any] = [
            "timestamp": entry.formattedTimestamp,
            "level": entry.level.name,
            "message": entry.message,
            "file": entry.fileName,
            "function": entry.function,
            "line": entry.line
        ]

        if let category = entry.category {
            json["category"] = category
        }

        if !entry.metadata.isEmpty {
            json["metadata"] = entry.metadata
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Failed to serialize log entry to JSON: \(error)"
        }
    }
}
