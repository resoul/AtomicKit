import Foundation

public final class FileLogger: LoggerImpl {
    private let fileDestination: FileDestination

    public init(
        minimumLevel: LogLevel = .info,
        category: String? = nil,
        formatter: LogFormatter = LogFormatterImpl(),
        fileDestination: FileDestination
    ) {
        self.fileDestination = fileDestination
        super.init(
            minimumLevel: minimumLevel,
            category: category,
            formatter: formatter,
            destination: fileDestination
        )
    }

    public convenience init(
        minimumLevel: LogLevel = .info,
        category: String? = nil,
        formatter: LogFormatter = LogFormatterImpl(),
        fileURL: URL? = nil,
        maxFileSize: Int = 10 * 1024 * 1024, // 10MB
        maxBackupCount: Int = 5
    ) {
        let destination = FileDestination(
            fileURL: fileURL,
            maxFileSize: maxFileSize,
            maxBackupCount: maxBackupCount
        )

        self.init(
            minimumLevel: minimumLevel,
            category: category,
            formatter: formatter,
            fileDestination: destination
        )
    }

    public func flush() {
        fileDestination.flush()
    }
}
