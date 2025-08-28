import Foundation

public struct CompactLogFormatter: LogFormatter {
    public init() {}

    public func format(_ entry: LogEntry) -> String {
        let time = entry.formattedTimestamp.suffix(12) // Only time part
        return "\(time) \(entry.level.emoji) \(entry.fileName):\(entry.line) - \(entry.message)"
    }
}