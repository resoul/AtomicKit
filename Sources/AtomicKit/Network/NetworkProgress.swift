import Foundation
import Combine

public final class NetworkProgress {
    public private(set) var uploadProgress: Double = 0.0 {
        didSet {
            uploadProgressSubject.send(uploadProgress)
        }
    }

    public private(set) var downloadProgress: Double = 0.0 {
        didSet {
            downloadProgressSubject.send(downloadProgress)
        }
    }

    public private(set) var isUploading = false {
        didSet {
            isUploadingSubject.send(isUploading)
        }
    }

    public private(set) var isDownloading = false {
        didSet {
            isDownloadingSubject.send(isDownloading)
        }
    }

    private let uploadProgressSubject = CurrentValueSubject<Double, Never>(0.0)
    private let downloadProgressSubject = CurrentValueSubject<Double, Never>(0.0)
    private let isUploadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isDownloadingSubject = CurrentValueSubject<Bool, Never>(false)

    public var uploadProgressPublisher: AnyPublisher<Double, Never> {
        uploadProgressSubject.eraseToAnyPublisher()
    }

    public var downloadProgressPublisher: AnyPublisher<Double, Never> {
        downloadProgressSubject.eraseToAnyPublisher()
    }

    public var isUploadingPublisher: AnyPublisher<Bool, Never> {
        isUploadingSubject.eraseToAnyPublisher()
    }

    public var isDownloadingPublisher: AnyPublisher<Bool, Never> {
        isDownloadingSubject.eraseToAnyPublisher()
    }

    private let logger = CategorizedLogger(category: "NetworkProgress")

    public init() {}

    public func startUpload(totalBytes: Int64) {
        isUploading = true
        uploadProgress = 0.0

        logger.debug("Upload started", metadata: ["totalBytes": totalBytes])
    }

    public func updateUploadProgress(bytesSent: Int64, totalBytes: Int64) {
        let progress = Double(bytesSent) / Double(totalBytes)
        uploadProgress = progress

        if progress >= 1.0 {
            completeUpload()
        }
    }

    public func completeUpload() {
        isUploading = false
        uploadProgress = 1.0

        logger.info("Upload completed")
    }

    public func startDownload(totalBytes: Int64) {
        isDownloading = true
        downloadProgress = 0.0

        logger.debug("Download started", metadata: ["totalBytes": totalBytes])
    }

    public func updateDownloadProgress(bytesReceived: Int64, totalBytes: Int64) {
        let progress = Double(bytesReceived) / Double(totalBytes)
        downloadProgress = progress

        if progress >= 1.0 {
            completeDownload()
        }
    }

    public func completeDownload() {
        isDownloading = false
        downloadProgress = 1.0

        logger.info("Download completed")
    }
}