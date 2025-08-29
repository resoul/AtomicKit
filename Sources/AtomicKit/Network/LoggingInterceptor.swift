import Foundation
import Combine

public final class LoggingInterceptor: RequestInterceptor, ResponseInterceptor {
    private let logger = CategorizedLogger(category: "NetworkLogging")
    private let logLevel: LogLevel
    private let logHeaders: Bool
    private let logBody: Bool

    public init(
        logLevel: LogLevel = .debug,
        logHeaders: Bool = true,
        logBody: Bool = false
    ) {
        self.logLevel = logLevel
        self.logHeaders = logHeaders
        self.logBody = logBody
    }

    public func intercept(_ request: NetworkRequest) -> AnyPublisher<NetworkRequest, NetworkError> {
        var metadata: [String: Any] = [
            "url": request.url.absoluteString,
            "method": request.method.rawValue
        ]

        if logHeaders {
            metadata["headers"] = request.headers
        }

        if logBody, let body = request.body {
            if let bodyString = String(data: body, encoding: .utf8) {
                metadata["body"] = bodyString
            } else {
                metadata["bodySize"] = body.count
            }
        }

        logger.log(level: logLevel, message: "→ Outgoing Request", metadata: metadata)

        return Just(request)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }

    public func intercept(_ response: NetworkResponse) -> AnyPublisher<NetworkResponse, NetworkError> {
        var metadata: [String: Any] = [
            "url": response.request.url.absoluteString,
            "statusCode": response.statusCode,
            "responseSize": response.data.count
        ]

        if logHeaders {
            metadata["headers"] = response.headers
        }

        if logBody {
            if let responseString = String(data: response.data, encoding: .utf8) {
                metadata["body"] = responseString
            }
        }

        let level: LogLevel = response.isSuccess ? logLevel : .error
        logger.log(level: level, message: "← Incoming Response", metadata: metadata)

        return Just(response)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}