import Foundation
import Combine

public final class RateLimitingInterceptor: RequestInterceptor {
    private let maxRequestsPerSecond: Int
    private let queue = DispatchQueue(label: "rate-limiter", qos: .utility)
    private var requestTimes: [Date] = []
    private let logger = CategorizedLogger(category: "RateLimit")

    public init(maxRequestsPerSecond: Int) {
        self.maxRequestsPerSecond = maxRequestsPerSecond
    }

    public func intercept(_ request: NetworkRequest) -> AnyPublisher<NetworkRequest, NetworkError> {
        return Future<NetworkRequest, NetworkError> { [weak self] promise in
            self?.queue.async {
                guard let self = self else {
                    promise(.failure(.cancelled))
                    return
                }

                let now = Date()

                // Remove requests older than 1 second
                self.requestTimes = self.requestTimes.filter { now.timeIntervalSince($0) < 1.0 }

                if self.requestTimes.count >= self.maxRequestsPerSecond {
                    // Calculate delay needed
                    let oldestRequest = self.requestTimes.min() ?? now
                    let delay = 1.0 - now.timeIntervalSince(oldestRequest)

                    self.logger.debug("Rate limit reached, delaying request", metadata: [
                        "delay": delay,
                        "requestsInLastSecond": self.requestTimes.count
                    ])

                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.requestTimes.append(Date())
                        promise(.success(request))
                    }
                } else {
                    self.requestTimes.append(now)
                    promise(.success(request))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}