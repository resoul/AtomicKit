import Foundation
import os.log

public class FileDestination: LogDestination {
    private let fileURL: URL
    private let maxFileSize: Int
    private let maxBackupCount: Int
    private let fileManager = FileManager.default
    private var fileHandle: FileHandle?

    public init(
        fileURL: URL? = nil,
        maxFileSize: Int = 10 * 1024 * 1024,
        maxBackupCount: Int = 5
    ) {
        if let url = fileURL {
            self.fileURL = url
        } else {
            // Default to Documents/Logs/app.log
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let logsDirectory = documentsPath.appendingPathComponent("Logs", isDirectory: true)

            try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            self.fileURL = logsDirectory.appendingPathComponent("app.log")
        }

        self.maxFileSize = maxFileSize
        self.maxBackupCount = maxBackupCount

        setupFile()
    }

    private func setupFile() {
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }

        do {
            fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle?.seekToEndOfFile()
        } catch {
            print("Failed to open log file: \(error)")
        }
    }

    public func write(_ formattedMessage: String) {
        guard let fileHandle = fileHandle else { return }

        let message = formattedMessage + "\n"
        guard let data = message.data(using: .utf8) else { return }

        fileHandle.write(data)

        // Check file size and rotate if needed
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int, fileSize > maxFileSize {
                rotateFile()
            }
        } catch {
            print("Failed to check file size: \(error)")
        }
    }

    public func flush() {
        fileHandle?.synchronizeFile()
    }

    private func rotateFile() {
        fileHandle?.closeFile()

        // Move existing backups
        for i in stride(from: maxBackupCount - 1, through: 1, by: -1) {
            let oldBackup = fileURL.appendingPathExtension("\(i)")
            let newBackup = fileURL.appendingPathExtension("\(i + 1)")

            if fileManager.fileExists(atPath: oldBackup.path) {
                try? fileManager.moveItem(at: oldBackup, to: newBackup)
            }
        }

        // Move current log to .1
        let firstBackup = fileURL.appendingPathExtension("1")
        try? fileManager.moveItem(at: fileURL, to: firstBackup)

        // Create new log file
        setupFile()
    }

    deinit {
        fileHandle?.closeFile()
    }
}