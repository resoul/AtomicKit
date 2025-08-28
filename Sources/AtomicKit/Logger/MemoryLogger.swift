import Foundation
import os.log

// MARK: - Memory Logger (for tests/debugging)
public final class MemoryLogger: Logger {
    public var minimumLevel: LogLevel
    public var category: String?

    private var _entries: [LogEntry] = []
    private let lock = NSLock()

    public var entries: [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries
    }

    public init(minimumLevel: LogLevel = .verbose, category: String? = nil) {
        self.minimumLevel = minimumLevel
        self.category = category
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        lock.lock()
        _entries.append(entry)
        lock.unlock()
    }

    public func clear() {
        lock.lock()
        _entries.removeAll()
        lock.unlock()
    }

    public func entries(for level: LogLevel) -> [LogEntry] {
        return entries.filter { $0.level == level }
    }

    public func entries(containing text: String) -> [LogEntry] {
        return entries.filter { $0.message.contains(text) }
    }
}