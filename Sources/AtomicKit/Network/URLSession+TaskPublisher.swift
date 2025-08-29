import Foundation
import Combine

extension URLSession {
    func uploadTaskPublisher(for request: URLRequest, from data: Data) -> URLSession.DataTaskPublisher {
        var uploadRequest = request
        uploadRequest.httpBody = data
        return dataTaskPublisher(for: uploadRequest)
    }

    func downloadTaskPublisher(for request: URLRequest) -> AnyPublisher<(URL, URLResponse), URLError> {
        return Future<(URL, URLResponse), URLError> { promise in
            let task = self.downloadTask(with: request) { url, response, error in
                if let error = error as? URLError {
                    promise(.failure(error))
                } else if let url = url, let response = response {
                    promise(.success((url, response)))
                } else {
                    promise(.failure(URLError(.unknown)))
                }
            }
            task.resume()
        }
        .eraseToAnyPublisher()
    }
}