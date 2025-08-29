import Foundation
import Security
import CoreData

final class MemoryCache<T> {
    private struct CacheItem {
        let value: T
        let timestamp: Date
        var accessCount: Int = 0
        var lastAccessed: Date

        init(value: T) {
            self.value = value
            self.timestamp = Date()
            self.lastAccessed = Date()
        }
    }

    private var cache: [String: CacheItem] = [:]
    private let queue = DispatchQueue(label: "memory-cache", attributes: .concurrent)
    private var policy: CachePolicy

    init(policy: CachePolicy = .default) {
        self.policy = policy
    }

    func get(_ key: String) -> T? {
        return queue.sync {
            guard var item = cache[key] else { return nil }

            // Check TTL
            if Date().timeIntervalSince(item.timestamp) > policy.ttl {
                cache.removeValue(forKey: key)
                return nil
            }

            // Update access info
            item.accessCount += 1
            item.lastAccessed = Date()
            cache[key] = item

            return item.value
        }
    }

    func set(_ value: T, for key: String) {
        queue.async(flags: .barrier) {
            // Remove oldest items if needed
            if self.cache.count >= self.policy.maxSize {
                self.evictItems()
            }

            self.cache[key] = CacheItem(value: value)
        }
    }

    func remove(_ key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }

    private func evictItems() {
        let itemsToRemove = max(1, cache.count - policy.maxSize + 1)

        let sortedKeys: [String]
        switch policy.strategy {
        case .lru:
            sortedKeys = cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }.map(\.key)
        case .fifo:
            sortedKeys = cache.sorted { $0.value.timestamp < $1.value.timestamp }.map(\.key)
        case .lfu:
            sortedKeys = cache.sorted { $0.value.accessCount < $1.value.accessCount }.map(\.key)
        case .none:
            return
        }

        for i in 0..<min(itemsToRemove, sortedKeys.count) {
            cache.removeValue(forKey: sortedKeys[i])
        }
    }
}