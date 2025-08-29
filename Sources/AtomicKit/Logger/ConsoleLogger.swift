import Foundation

public final class ConsoleLogger: LoggerImpl {
    public convenience init(
        minimumLevel: LogLevel = .info,
        category: String? = nil,
        formatter: LogFormatter = LogFormatterImpl()
    ) {
        self.init(
            minimumLevel: minimumLevel,
            category: category,
            formatter: formatter,
            destination: ConsoleDestination()
        )
    }
}
