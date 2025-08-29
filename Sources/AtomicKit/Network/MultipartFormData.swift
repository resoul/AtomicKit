import Foundation
import Combine

public final class MultipartFormDataBuilder {
    private var parts: [MultipartFormDataPart] = []
    private let boundary = UUID().uuidString

    public init() {}

    public func addTextField(_ name: String, value: String) -> MultipartFormDataBuilder {
        let part = MultipartFormDataPart(
            name: name,
            data: value.data(using: .utf8) ?? Data(),
            mimeType: "text/plain"
        )
        parts.append(part)
        return self
    }

    public func addFileField(_ name: String, data: Data, fileName: String, mimeType: String) -> MultipartFormDataBuilder {
        let part = MultipartFormDataPart(
            name: name,
            data: data,
            fileName: fileName,
            mimeType: mimeType
        )
        parts.append(part)
        return self
    }

    public func build() -> (data: Data, contentType: String) {
        var body = Data()

        for part in parts {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)

            var contentDisposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let fileName = part.fileName {
                contentDisposition += "; filename=\"\(fileName)\""
            }
            body.append("\(contentDisposition)\r\n".data(using: .utf8)!)

            body.append("Content-Type: \(part.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(part.data)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let contentType = "multipart/form-data; boundary=\(boundary)"
        return (body, contentType)
    }
}

private struct MultipartFormDataPart {
    let name: String
    let data: Data
    let fileName: String?
    let mimeType: String

    init(name: String, data: Data, fileName: String? = nil, mimeType: String) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}