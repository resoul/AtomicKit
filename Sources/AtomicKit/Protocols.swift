import UIKit

// MARK: - Base Protocols
public protocol UseCase {}
public protocol Repository {}
public protocol DataSource {}
public protocol Service {}
public protocol ViewModel: AnyObject {}



// MARK: - Lifecycle
public protocol Disposable {
    func dispose()
}

// MARK: - Scopes
public enum DIScope {
    case singleton
    case transient
    case scoped
}
