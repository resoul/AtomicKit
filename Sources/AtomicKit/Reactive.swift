import UIKit
import Combine

extension UIButton {
    public var tapPublisher: AnyPublisher<Void, Never> {
        controlPublisher(for: .touchUpInside).map { _ in }.eraseToAnyPublisher()
    }
}

extension UITextField {
    public var textPublisher: AnyPublisher<String, Never> {
        controlPublisher(for: .editingChanged)
            .map { ($0 as? UITextField)?.text ?? "" }
            .eraseToAnyPublisher()
    }
}

extension UIControl {
    public func controlPublisher(for event: UIControl.Event) -> AnyPublisher<UIControl, Never> {
        return UIControlPublisher(control: self, event: event).eraseToAnyPublisher()
    }
}

private struct UIControlPublisher: Publisher {
    typealias Output = UIControl
    typealias Failure = Never

    let control: UIControl
    let event: UIControl.Event

    func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, UIControl == S.Input {
        let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: event)
        subscriber.receive(subscription: subscription)
    }
}

private final class UIControlSubscription<S: Subscriber>: Subscription where S.Input == UIControl, S.Failure == Never {
    private var subscriber: S?
    private weak var control: UIControl?
    private let event: UIControl.Event

    init(subscriber: S, control: UIControl, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        self.event = event
        control.addTarget(self, action: #selector(handleEvent), for: event)
    }

    func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
    }

    func cancel() {
        control?.removeTarget(self, action: #selector(handleEvent), for: event)
        subscriber = nil
    }

    @objc private func handleEvent() {
        guard let control = control else { return }
        _ = subscriber?.receive(control)
    }
}