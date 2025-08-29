import Foundation
import Security
import CoreData

struct CachePolicy {
    let maxSize: Int
    let ttl: TimeInterval
    let strategy: CacheStrategy

    enum CacheStrategy {
        case lru
        case fifo
        case lfu
        case none
    }

    static let `default` = CachePolicy(maxSize: 100, ttl: 300, strategy: .lru)
}