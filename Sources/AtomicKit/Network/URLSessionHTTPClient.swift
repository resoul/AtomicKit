import Foundation
import Combine

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let configuration: NetworkConfiguration
    private let logger: CategorizedLogger
    private var cancellables = Set<AnyCancellable>()

    public init(
        session: URLSession = .shared,
        configuration: NetworkConfiguration,
        logger: Logger? = nil
    ) {
        self.session = session
        self.configuration = configuration
        self.logger = CategorizedLogger(
            logger: logger ?? AtomicLogger.shared,
            category: "Network"
        )
    }

    public func execute(_ request: NetworkRequest) -> AnyPublisher<NetworkResponse, NetworkError> {
        return createURLRequest(from: request)
            .flatMap { [weak self] urlRequest -> AnyPublisher<NetworkResponse, NetworkError> in
                guard let self = self else {
                    return Fail(error: NetworkError.cancelled)
                        .eraseToAnyPublisher()
                }

                return self.performRequest(urlRequest, originalRequest: request)
            }
            .retry(request.retryCount)
            .eraseToAnyPublisher()
    }

    public func execute<T: Decodable>(_ request: NetworkRequest, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        return execute(request)
            .tryMap { response in
                do {
                    return try JSONDecoder().decode(T.self, from: response.data)
                } catch {
                    throw NetworkError.decodingError(error)
                }
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.decodingError(error)
                }
            }
            .eraseToAnyPublisher()
    }

    public func upload(_ request: NetworkRequest, data: Data) -> AnyPublisher<NetworkResponse, NetworkError> {
        return createURLRequest(from: request)
            .flatMap { [weak self] urlRequest -> AnyPublisher<NetworkResponse, NetworkError> in
                guard let self = self else {
                    return Fail(error: NetworkError.cancelled)
                        .eraseToAnyPublisher()
                }

                self.logger.debug("Starting upload", metadata: [
                    "url": request.url.absoluteString,
                    "method": request.method.rawValue,
                    "dataSize": data.count
                ])

                return self.session.uploadTaskPublisher(for: urlRequest, from: data)
                    .tryMap { data, response -> NetworkResponse in
                        try self.handleResponse(data: data, response: response, request: request)
                    }
                    .mapError { error in
                        self.handleError(error, request: request)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func download(_ request: NetworkRequest) -> AnyPublisher<URL, NetworkError> {
        return createURLRequest(from: request)
            .flatMap { [weak self] urlRequest -> AnyPublisher<URL, NetworkError> in
                guard let self = self else {
                    return Fail(error: NetworkError.cancelled)
                        .eraseToAnyPublisher()
                }

                self.logger.debug("Starting download", metadata: [
                    "url": request.url.absoluteString
                ])

                return self.session.downloadTaskPublisher(for: urlRequest)
                    .tryMap { url, response -> URL in
                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw NetworkError.invalidResponse
                        }

                        guard 200...299 ~= httpResponse.statusCode else {
                            throw NetworkError.httpError(httpResponse.statusCode, nil)
                        }

                        return url
                    }
                    .mapError { error in
                        self.handleError(error, request: request)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func createURLRequest(from request: NetworkRequest) -> AnyPublisher<URLRequest, NetworkError> {
        var urlRequest = URLRequest(
            url: request.url,
            cachePolicy: request.cachePolicy,
            timeoutInterval: request.timeout
        )

        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        // Set headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Apply request interceptors
        return applyRequestInterceptors(to: NetworkRequest(
            url: request.url,
            method: request.method,
            headers: request.headers,
            body: request.body,
            encoding: request.encoding,
            timeout: request.timeout,
            retryCount: request.retryCount,
            cachePolicy: request.cachePolicy
        ))
        .map { interceptedRequest in
            var finalURLRequest = urlRequest
            finalURLRequest.url = interceptedRequest.url
            finalURLRequest.httpMethod = interceptedRequest.method.rawValue
            finalURLRequest.httpBody = interceptedRequest.body
            finalURLRequest.timeoutInterval = interceptedRequest.timeout
            finalURLRequest.cachePolicy = interceptedRequest.cachePolicy

            // Update headers
            finalURLRequest.allHTTPHeaderFields = interceptedRequest.headers

            return finalURLRequest
        }
        .eraseToAnyPublisher()
    }

    private func performRequest(_ urlRequest: URLRequest, originalRequest: NetworkRequest) -> AnyPublisher<NetworkResponse, NetworkError> {
        let startTime = Date()

        if configuration.enableLogging {
            logger.debug("Starting request", metadata: [
                "url": originalRequest.url.absoluteString,
                "method": originalRequest.method.rawValue,
                "headers": originalRequest.headers
            ])
        }

        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] data, response -> NetworkResponse in
                guard let self = self else {
                    throw NetworkError.cancelled
                }

                let networkResponse = try self.handleResponse(
                    data: data,
                    response: response,
                    request: originalRequest
                )

                if self.configuration.enableLogging {
                    let duration = Date().timeIntervalSince(startTime)
                    self.logger.info("Request completed", metadata: [
                        "url": originalRequest.url.absoluteString,
                        "statusCode": networkResponse.statusCode,
                        "duration": String(format: "%.3f", duration * 1000) + "ms",
                        "responseSize": data.count
                    ])
                }

                return networkResponse
            }
            .mapError { [weak self] error in
                if let self = self, self.configuration.enableLogging {
                    let duration = Date().timeIntervalSince(startTime)
                    self.logger.error("Request failed", metadata: [
                        "url": originalRequest.url.absoluteString,
                        "error": error.localizedDescription,
                        "duration": String(format: "%.3f", duration * 1000) + "ms"
                    ])
                }

                return self?.handleError(error, request: originalRequest) ?? NetworkError.unknown(error)
            }
            .flatMap { [weak self] response -> AnyPublisher<NetworkResponse, NetworkError> in
                guard let self = self else {
                    return Just(response).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                }

                return self.applyResponseInterceptors(to: response)
            }
            .eraseToAnyPublisher()
    }

    private func handleResponse(data: Data, response: URLResponse, request: NetworkRequest) throws -> NetworkResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        let networkResponse = NetworkResponse(data: data, response: httpResponse, request: request)

        guard networkResponse.isSuccess else {
            throw NetworkError.httpError(httpResponse.statusCode, data)
        }

        return networkResponse
    }

    private func handleError(_ error: Error, request: NetworkRequest) -> NetworkError {
        switch error {
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            default:
                return .unknown(urlError)
            }
        case let networkError as NetworkError:
            return networkError
        default:
            return .unknown(error)
        }
    }

    private func applyRequestInterceptors(to request: NetworkRequest) -> AnyPublisher<NetworkRequest, NetworkError> {
        configuration.requestInterceptors.reduce(
            Just(request).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
        ) { publisher, interceptor in
            publisher.flatMap { interceptor.intercept($0) }.eraseToAnyPublisher()
        }
    }

    private func applyResponseInterceptors(to response: NetworkResponse) -> AnyPublisher<NetworkResponse, NetworkError> {
        configuration.responseInterceptors.reduce(
            Just(response).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
        ) { publisher, interceptor in
            publisher.flatMap { interceptor.intercept($0) }.eraseToAnyPublisher()
        }
    }
}