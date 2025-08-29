import Foundation
import Combine

public enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
}

public enum RequestEncoding {
    case json
    case urlEncoded
    case multipart
    case custom(String)

    public var contentType: String {
        switch self {
        case .json:
            return "application/json"
        case .urlEncoded:
            return "application/x-www-form-urlencoded"
        case .multipart:
            return "multipart/form-data"
        case .custom(let type):
            return type
        }
    }
}

// MARK: - mock Request
public struct NetworkRequest {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?
    public let encoding: RequestEncoding
    public let timeout: TimeInterval
    public let retryCount: Int
    public let cachePolicy: URLRequest.CachePolicy

    public init(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        encoding: RequestEncoding = .json,
        timeout: TimeInterval = 30.0,
        retryCount: Int = 0,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.encoding = encoding
        self.timeout = timeout
        self.retryCount = retryCount
        self.cachePolicy = cachePolicy
    }
}

// MARK: - mock Response
public struct NetworkResponse {
    public let data: Data
    public let response: HTTPURLResponse
    public let request: NetworkRequest

    public init(data: Data, response: HTTPURLResponse, request: NetworkRequest) {
        self.data = data
        self.response = response
        self.request = request
    }

    public var statusCode: Int {
        return response.statusCode
    }

    public var isSuccess: Bool {
        return 200...299 ~= statusCode
    }

    public var headers: [AnyHashable: Any] {
        return response.allHeaderFields
    }
}

// MARK: - mock Errors
public enum NetworkError: Error, LocalizedError {
    case invalidURL(String)
    case noData
    case invalidResponse
    case httpError(Int, Data?)
    case decodingError(Error)
    case encodingError(Error)
    case timeout
    case noInternetConnection
    case cancelled
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response format"
        case .httpError(let code, _):
            return "HTTP Error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .timeout:
            return "Request timeout"
        case .noInternetConnection:
            return "No internet connection"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    public var statusCode: Int? {
        switch self {
        case .httpError(let code, _):
            return code
        default:
            return nil
        }
    }

    public var responseData: Data? {
        switch self {
        case .httpError(_, let data):
            return data
        default:
            return nil
        }
    }
}

// MARK: - Request Building
public protocol RequestBuilder {
    func build() -> NetworkRequest
}

public class URLRequestBuilder: RequestBuilder {
    private var baseURL: URL
    private var path: String = ""
    private var method: HTTPMethod = .GET
    private var headers: [String: String] = [:]
    private var queryParameters: [String: Any] = [:]
    private var body: Data?
    private var encoding: RequestEncoding = .json
    private var timeout: TimeInterval = 30.0
    private var retryCount: Int = 0
    private var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    @discardableResult
    public func path(_ path: String) -> URLRequestBuilder {
        self.path = path
        return self
    }

    @discardableResult
    public func method(_ method: HTTPMethod) -> URLRequestBuilder {
        self.method = method
        return self
    }

    @discardableResult
    public func header(_ key: String, _ value: String) -> URLRequestBuilder {
        headers[key] = value
        return self
    }

    @discardableResult
    public func headers(_ headers: [String: String]) -> URLRequestBuilder {
        self.headers.merge(headers) { _, new in new }
        return self
    }

    @discardableResult
    public func query(_ key: String, _ value: Any) -> URLRequestBuilder {
        queryParameters[key] = value
        return self
    }

    @discardableResult
    public func queryParameters(_ parameters: [String: Any]) -> URLRequestBuilder {
        self.queryParameters.merge(parameters) { _, new in new }
        return self
    }

    @discardableResult
    public func body<T: Encodable>(_ object: T, encoding: RequestEncoding = .json) -> URLRequestBuilder {
        do {
            switch encoding {
            case .json:
                self.body = try JSONEncoder().encode(object)
            case .urlEncoded:
                if let dict = try object.asDictionary() {
                    self.body = dict.percentEncoded()
                }
            default:
                break
            }
            self.encoding = encoding
        } catch {
            // Handle encoding error
        }
        return self
    }

    @discardableResult
    public func body(_ data: Data, encoding: RequestEncoding = .json) -> URLRequestBuilder {
        self.body = data
        self.encoding = encoding
        return self
    }

    @discardableResult
    public func timeout(_ timeout: TimeInterval) -> URLRequestBuilder {
        self.timeout = timeout
        return self
    }

    @discardableResult
    public func retry(_ count: Int) -> URLRequestBuilder {
        self.retryCount = count
        return self
    }

    @discardableResult
    public func cachePolicy(_ policy: URLRequest.CachePolicy) -> URLRequestBuilder {
        self.cachePolicy = policy
        return self
    }

    public func build() -> NetworkRequest {
        var url = baseURL.appendingPathComponent(path)

        // Add query parameters
        if !queryParameters.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            url = components?.url ?? url
        }

        // Set content type header if body is present
        var finalHeaders = headers
        if body != nil && finalHeaders["Content-Type"] == nil {
            finalHeaders["Content-Type"] = encoding.contentType
        }

        return NetworkRequest(
            url: url,
            method: method,
            headers: finalHeaders,
            body: body,
            encoding: encoding,
            timeout: timeout,
            retryCount: retryCount,
            cachePolicy: cachePolicy
        )
    }
}

// MARK: - HTTP Client Protocol
public protocol HTTPClient {
    func execute(_ request: NetworkRequest) -> AnyPublisher<NetworkResponse, NetworkError>
    func execute<T: Decodable>(_ request: NetworkRequest, responseType: T.Type) -> AnyPublisher<T, NetworkError>
    func upload(_ request: NetworkRequest, data: Data) -> AnyPublisher<NetworkResponse, NetworkError>
    func download(_ request: NetworkRequest) -> AnyPublisher<URL, NetworkError>
}

// MARK: - mock Service Protocol
public protocol NetworkService: Service {
    var baseURL: URL { get }
    var defaultHeaders: [String: String] { get }
    var httpClient: HTTPClient { get }

    func requestBuilder() -> URLRequestBuilder
}

public extension NetworkService {
    func requestBuilder() -> URLRequestBuilder {
        return URLRequestBuilder(baseURL: baseURL)
            .headers(defaultHeaders)
    }
}

// MARK: - Request/Response Interceptors
public protocol RequestInterceptor {
    func intercept(_ request: NetworkRequest) -> AnyPublisher<NetworkRequest, NetworkError>
}

public protocol ResponseInterceptor {
    func intercept(_ response: NetworkResponse) -> AnyPublisher<NetworkResponse, NetworkError>
}

// MARK: - mock Configuration
public struct NetworkConfiguration {
    public let baseURL: URL
    public let timeout: TimeInterval
    public let retryCount: Int
    public let defaultHeaders: [String: String]
    public let requestInterceptors: [RequestInterceptor]
    public let responseInterceptors: [ResponseInterceptor]
    public let enableLogging: Bool

    public init(
        baseURL: URL,
        timeout: TimeInterval = 30.0,
        retryCount: Int = 3,
        defaultHeaders: [String: String] = [:],
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        enableLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.retryCount = retryCount
        self.defaultHeaders = defaultHeaders
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.enableLogging = enableLogging
    }
}

// MARK: - Pagination Support
public protocol Paginated {
    associatedtype Item
    var items: [Item] { get }
    var hasNextPage: Bool { get }
    var nextPageToken: String? { get }
    var totalCount: Int? { get }
}

public struct PaginatedResponse<T>: Paginated, Decodable where T: Decodable {
    public let items: [T]
    public let hasNextPage: Bool
    public let nextPageToken: String?
    public let totalCount: Int?
    public let page: Int?
    public let pageSize: Int?

    public init(
        items: [T],
        hasNextPage: Bool = false,
        nextPageToken: String? = nil,
        totalCount: Int? = nil,
        page: Int? = nil,
        pageSize: Int? = nil
    ) {
        self.items = items
        self.hasNextPage = hasNextPage
        self.nextPageToken = nextPageToken
        self.totalCount = totalCount
        self.page = page
        self.pageSize = pageSize
    }
}

// MARK: - Supporting Extensions
extension Encodable {
    func asDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return dictionary
    }
}

extension Dictionary where Key == String, Value == Any {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return "\(escapedKey)=\(escapedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

extension HTTPClient {
    public func execute(_ request: NetworkRequest) async throws -> NetworkResponse {
        return try await execute(request).async()
    }

    public func execute<T: Decodable>(_ request: NetworkRequest, responseType: T.Type) async throws -> T {
        return try await execute(request, responseType: responseType).async()
    }
}

extension Publisher {
    public func async() async throws -> Output {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
}

public struct GraphQLRequest {
    public let query: String
    public let variables: [String: Any]?
    public let operationName: String?

    public init(query: String, variables: [String: Any]? = nil, operationName: String? = nil) {
        self.query = query
        self.variables = variables
        self.operationName = operationName
    }
}

public protocol GraphQLClient {
    func execute<T: Decodable>(_ request: GraphQLRequest, responseType: T.Type) -> AnyPublisher<T, NetworkError>
}