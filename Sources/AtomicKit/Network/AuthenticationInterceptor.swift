import Foundation
import Combine

public final class AuthenticationInterceptor: RequestInterceptor {
    public enum AuthType {
        case bearer(String)
        case basic(username: String, password: String)
        case apiKey(key: String, header: String)
        case custom(header: String, value: String)
    }

    private let authType: AuthType
    private let logger = CategorizedLogger(category: "Auth")

    public init(authType: AuthType) {
        self.authType = authType
    }

    public func intercept(_ request: NetworkRequest) -> AnyPublisher<NetworkRequest, NetworkError> {
        var modifiedHeaders = request.headers

        switch authType {
        case .bearer(let token):
            modifiedHeaders["Authorization"] = "Bearer \(token)"
            logger.debug("Added Bearer token to request")

        case .basic(let username, let password):
            let credentials = "\(username):\(password)"
            let encodedCredentials = Data(credentials.utf8).base64EncodedString()
            modifiedHeaders["Authorization"] = "Basic \(encodedCredentials)"
            logger.debug("Added Basic auth to request")

        case .apiKey(let key, let header):
            modifiedHeaders[header] = key
            logger.debug("Added API key to request", metadata: ["header": header])

        case .custom(let header, let value):
            modifiedHeaders[header] = value
            logger.debug("Added custom auth header to request", metadata: ["header": header])
        }

        let modifiedRequest = NetworkRequest(
            url: request.url,
            method: request.method,
            headers: modifiedHeaders,
            body: request.body,
            encoding: request.encoding,
            timeout: request.timeout,
            retryCount: request.retryCount,
            cachePolicy: request.cachePolicy
        )

        return Just(modifiedRequest)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}