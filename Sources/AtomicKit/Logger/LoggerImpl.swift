import Foundation
import os.log

open class LoggerImpl: Logger {
    public var minimumLevel: LogLevel
    public var category: String?

    private let formatter: LogFormatter
    private let destination: LogDestination
    private let queue: DispatchQueue

    public init(
        minimumLevel: LogLevel = .info,
        category: String? = nil,
        formatter: LogFormatter = LogFormatterImpl(),
        destination: LogDestination = ConsoleDestination()
    ) {
        self.minimumLevel = minimumLevel
        self.category = category
        self.formatter = formatter
        self.destination = destination
        self.queue = DispatchQueue(label: "com.atomickit.logger", qos: .utility)
    }

    public func log(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }

        queue.async { [weak self] in
            guard let self = self else { return }
            let formatted = self.formatter.format(entry)
            self.destination.write(formatted)
        }
    }
}
