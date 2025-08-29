import Foundation
import os.log

public final class OSLogger: Logger {
    public var minimumLevel: LogLevel
    public var category: String? {
        didSet {
            updateOSLog()
        }
    }

    private var osLog: OSLog
    private let subsystem: String

    public init(
        minimumLevel: LogLevel = .info,
        category: String? = nil,
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.atomickit"
    ) {
        self.minimumLevel = minimumLevel
        self.category = category
        self.subsystem = subsystem
        self.osLog = OSLog(subsystem: subsystem, category: category ?? "default")
    }

    private func updateOSLog() {
        osLog = OSLog(subsystem: subsystem, category: category ?? "default")
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        let osLogType = mapLogLevelToOSLogType(entry.level)
        let message = formatMessage(entry)

        os_log("%{public}@", log: osLog, type: osLogType, message)
    }

    private func mapLogLevelToOSLogType(_ level: LogLevel) -> OSLogType {
        switch level {
        case .verbose, .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }

    private func formatMessage(_ entry: LogEntry) -> String {
        var components = [entry.message]

        if !entry.metadata.isEmpty {
            let metadata = entry.metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            components.append("{\(metadata)}")
        }

        return components.joined(separator: " ")
    }
}
