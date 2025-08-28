import Foundation

public protocol LogFormatter {
    func format(_ entry: LogEntry) -> String
}

public struct LogFormatterImpl: LogFormatter {
    public init() {}

    public func format(_ entry: LogEntry) -> String {
        var components: [String] = []

        // Timestamp
        components.append("[\(entry.formattedTimestamp)]")

        // Level with emoji
        components.append("\(entry.level.emoji) \(entry.level.name)")

        // Category if present
        if let category = entry.category {
            components.append("[\(category)]")
        }

        // File:line
        components.append("[\(entry.fileName):\(entry.line)]")

        // Function
        components.append("[\(entry.function)]")

        // Message
        components.append("- \(entry.message)")

        // Metadata if present
        if !entry.metadata.isEmpty {
            let metadataString = entry.metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            components.append("{\(metadataString)}")
        }

        return components.joined(separator: " ")
    }
}
