import Foundation
import Combine

public final class PerformanceInterceptor: RequestInterceptor, ResponseInterceptor {
     private let performanceLogger = CategorizedLogger(category: "Performance")

     public func intercept(_ request: NetworkRequest) -> AnyPublisher<NetworkRequest, NetworkError> {
         request.metadata["startTime"] = CFAbsoluteTimeGetCurrent()
         return Just(request)
             .setFailureType(to: NetworkError.self)
             .eraseToAnyPublisher()
     }

     public func intercept(_ response: NetworkResponse) -> AnyPublisher<NetworkResponse, NetworkError> {
         if let startTime = response.request.metadata["startTime"] as? CFAbsoluteTime {
             let duration = CFAbsoluteTimeGetCurrent() - startTime

             performanceLogger.info("Request completed", metadata: [
                 "url": response.request.url.absoluteString,
                 "duration": duration,
                 "statusCode": response.statusCode,
                 "responseSize": response.data.count
             ])
         }

         return Just(response)
             .setFailureType(to: NetworkError.self)
             .eraseToAnyPublisher()
     }
 }