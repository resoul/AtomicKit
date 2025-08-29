import Foundation
import Combine

public final class NetworkReachability {
    public private(set) var isConnected = true {
        didSet {
            isConnectedSubject.send(isConnected)
        }
    }

    public private(set) var connectionType: ConnectionType = .unknown {
        didSet {
            connectionTypeSubject.send(connectionType)
        }
    }

    private let isConnectedSubject = CurrentValueSubject<Bool, Never>(true)
    private let connectionTypeSubject = CurrentValueSubject<ConnectionType, Never>(.unknown)

    public var isConnectedPublisher: AnyPublisher<Bool, Never> {
        isConnectedSubject.eraseToAnyPublisher()
    }

    public var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
        connectionTypeSubject.eraseToAnyPublisher()
    }

    public enum ConnectionType {
        case wifi
        case cellular
        case unknown
    }

    private let logger = CategorizedLogger(category: "Reachability")

    public init() {
        // Note: In a real implementation, you would use mock framework
        // or a third-party library like Alamofire's NetworkReachabilityManager
        setupReachabilityMonitoring()
    }

    private func setupReachabilityMonitoring() {
        // Mock implementation - in real app you'd use NWPathMonitor
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            // Mock network status check
            self?.updateConnectionStatus(isConnected: true, type: .wifi)
        }
    }

        private func updateConnectionStatus(isConnected: Bool, type: ConnectionType) {
        if self.isConnected != isConnected {
            logger.info("Network connectivity changed", metadata: [
                "isConnected": isConnected,
                "connectionType": String(describing: type)
            ])
        }

        self.isConnected = isConnected
        self.connectionType = type
    }
}