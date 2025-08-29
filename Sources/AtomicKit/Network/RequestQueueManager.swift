import Foundation
import Combine

public final class RequestQueueManager {
    public private(set) var pendingRequestsCount = 0 {
        didSet {
            pendingRequestsSubject.send(pendingRequestsCount)
        }
    }

    public private(set) var isProcessing = false {
        didSet {
            isProcessingSubject.send(isProcessing)
        }
    }

    private let pendingRequestsSubject = CurrentValueSubject<Int, Never>(0)
    private let isProcessingSubject = CurrentValueSubject<Bool, Never>(false)

    public var pendingRequestsPublisher: AnyPublisher<Int, Never> {
        pendingRequestsSubject.eraseToAnyPublisher()
    }

    public var isProcessingPublisher: AnyPublisher<Bool, Never> {
        isProcessingSubject.eraseToAnyPublisher()
    }

    private var requestQueue: [(NetworkRequest, (Result<NetworkResponse, NetworkError>) -> Void)] = []
    private let maxConcurrentRequests = 5
    private var activeRequests = 0
    private let queue = DispatchQueue(label: "request-queue", qos: .utility)
    private let logger = CategorizedLogger(category: "RequestQueue")

    public init() {}

    public func enqueue<T: Decodable>(
        _ request: NetworkRequest,
        httpClient: HTTPClient,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        return Future<T, NetworkError> { [weak self] promise in
            self?.queue.async {
                guard let self = self else {
                    promise(.failure(.cancelled))
                    return
                }

                self.logger.debug("Enqueueing request", metadata: [
                    "url": request.url.absoluteString,
                    "queueSize": self.requestQueue.count
                ])

                let requestCompletion: (Result<NetworkResponse, NetworkError>) -> Void = { result in
                    switch result {
                    case .success(let response):
                        do {
                            let decoded = try JSONDecoder().decode(T.self, from: response.data)
                            promise(.success(decoded))
                        } catch {
                            promise(.failure(.decodingError(error)))
                        }
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }

                self.requestQueue.append((request, requestCompletion))
                self.updatePendingCount()
                self.processQueue(httpClient: httpClient)
            }
        }
        .eraseToAnyPublisher()
    }

    private func processQueue(httpClient: HTTPClient) {
        guard activeRequests < maxConcurrentRequests,
              !requestQueue.isEmpty else { return }

        let (request, completion) = requestQueue.removeFirst()
        activeRequests += 1
        updatePendingCount()
        updateProcessingStatus()

        logger.debug("Processing request", metadata: [
            "url": request.url.absoluteString,
            "activeRequests": activeRequests
        ])

        httpClient.execute(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] publisherCompletion in
                    self?.queue.async {
                        guard let self = self else { return }

                        self.activeRequests -= 1
                        self.updatePendingCount()
                        self.updateProcessingStatus()

                        if case .failure(let error) = publisherCompletion {
                            completion(.failure(error))
                        }

                        // Process next request
                        self.processQueue(httpClient: httpClient)
                    }
                },
                receiveValue: { response in
                    completion(.success(response))
                }
            )
    }

    private func updatePendingCount() {
        pendingRequestsCount = requestQueue.count + activeRequests
    }

    private func updateProcessingStatus() {
        isProcessing = activeRequests > 0 || !requestQueue.isEmpty
    }
}