import Foundation
import Combine

public final class RetryInterceptor: ResponseInterceptor {
    private let maxRetries: Int
    private let retryableStatusCodes: Set<Int>
    private let backoffStrategy: BackoffStrategy
    private let logger = CategorizedLogger(category: "Retry")

    public enum BackoffStrategy {
        case linear(TimeInterval)
        case exponential(base: TimeInterval, multiplier: Double)
        case custom((Int) -> TimeInterval)
    }

    public init(
        maxRetries: Int = 3,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
        backoffStrategy: BackoffStrategy = .exponential(base: 1.0, multiplier: 2.0)
    ) {
        self.maxRetries = maxRetries
        self.retryableStatusCodes = retryableStatusCodes
        self.backoffStrategy = backoffStrategy
    }

    public func intercept(_ response: NetworkResponse) -> AnyPublisher<NetworkResponse, NetworkError> {
        if retryableStatusCodes.contains(response.statusCode) {
            logger.warning("Received retryable status code", metadata: [
                "statusCode": response.statusCode,
                "url": response.request.url.absoluteString
            ])
            return Fail(error: NetworkError.httpError(response.statusCode, response.data))
                .eraseToAnyPublisher()
        }

        return Just(response)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }

    private func calculateDelay(for attempt: Int) -> TimeInterval {
        switch backoffStrategy {
        case .linear(let interval):
            return interval * TimeInterval(attempt)
        case .exponential(let base, let multiplier):
            return base * pow(multiplier, Double(attempt - 1))
        case .custom(let calculator):
            return calculator(attempt)
        }
    }
}