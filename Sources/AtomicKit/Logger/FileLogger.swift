import Foundation
import os.log

public final class FileLogger: LoggerImpl {
    private let fileDestination: FileDestination

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

        self.fileDestination = destination

        self.init(
            minimumLevel: minimumLevel,
            category: category,
            formatter: formatter,
            destination: destination
        )
    }

    public func flush() {
        fileDestination.flush()
    }
}
