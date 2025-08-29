import Foundation
import Combine

public final class CachingInterceptor: RequestInterceptor, ResponseInterceptor {
    private let cache = URLCache.shared
    private let logger = CategorizedLogger(category: "NetworkCache")

    public func intercept(_ request: NetworkRequest) -> AnyPublisher<NetworkRequest, NetworkError> {
        // Check cache for GET requests
        if request.method == .GET {
            let urlRequest = URLRequest(url: request.url)
            if let cachedResponse = cache.cachedResponse(for: urlRequest) {
                logger.debug("Found cached response", metadata: [
                    "url": request.url.absoluteString
                ])
                // Note: In a real implementation, you might want to validate cache freshness
            }
        }

        return Just(request)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }

    public func intercept(_ response: NetworkResponse) -> AnyPublisher<NetworkResponse, NetworkError> {
        // Cache GET responses
        if response.request.method == .GET && response.isSuccess {
            let urlRequest = URLRequest(url: response.request.url)
            let cachedResponse = CachedURLResponse(response: response.response, data: response.data)
            cache.storeCachedResponse(cachedResponse, for: urlRequest)

            logger.debug("Cached response", metadata: [
                "url": response.request.url.absoluteString,
                "size": response.data.count
            ])
        }

        return Just(response)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}
