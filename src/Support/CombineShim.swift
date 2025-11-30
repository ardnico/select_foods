#if !canImport(Combine)
import Foundation
import Dispatch

// Minimal Combine replacements for Linux environments lacking the Combine framework.
public protocol Cancellable {
    func cancel()
}

public struct AnyCancellable: Cancellable, Hashable {
    private let cancelHandler: () -> Void
    private let id = UUID()

    public init(_ cancel: @escaping () -> Void = {}) {
        self.cancelHandler = cancel
    }

    public func cancel() {
        cancelHandler()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
        lhs.id == rhs.id
    }

    public func store(in set: inout Set<AnyCancellable>) {
        set.insert(self)
    }
}

public protocol ObservableObject {}

public struct AnyPublisher<Output, Failure: Error> {
    private let subscribe: (@escaping (Output) -> Void) -> AnyCancellable

    public init(_ subscribe: @escaping (@escaping (Output) -> Void) -> AnyCancellable) {
        self.subscribe = subscribe
    }

    @discardableResult
    public func sink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable {
        subscribe(receiveValue)
    }

    public func receive(on queue: DispatchQueue) -> AnyPublisher<Output, Failure> {
        self
    }

    public func eraseToAnyPublisher() -> AnyPublisher<Output, Failure> {
        self
    }
}

public struct Just<Output> {
    public let output: Output

    public init(_ output: Output) {
        self.output = output
    }

    @discardableResult
    public func sink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable {
        receiveValue(output)
        return AnyCancellable()
    }

    public func receive(on queue: DispatchQueue) -> AnyPublisher<Output, Never> {
        eraseToAnyPublisher()
    }

    public func eraseToAnyPublisher() -> AnyPublisher<Output, Never> {
        AnyPublisher { handler in
            handler(output)
            return AnyCancellable()
        }
    }
}

final class _PassthroughSubject<Output> {
    private var subscribers: [UUID: (Output) -> Void] = [:]
    private let lock = NSLock()

    func send(_ value: Output) {
        lock.lock(); let handlers = subscribers.values; lock.unlock()
        handlers.forEach { $0(value) }
    }

    func subscribe(_ handler: @escaping (Output) -> Void) -> AnyCancellable {
        let id = UUID()
        lock.lock(); subscribers[id] = handler; lock.unlock()
        return AnyCancellable { [weak self] in
            self?.lock.lock(); self?.subscribers.removeValue(forKey: id); self?.lock.unlock()
        }
    }
}

@propertyWrapper
public struct Published<Value> {
    private var value: Value
    private let subject = _PassthroughSubject<Value>()

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            subject.send(newValue)
        }
    }

    public var projectedValue: Publisher {
        Publisher(subject: subject, current: value)
    }

    public struct Publisher {
        private let subject: _PassthroughSubject<Value>
        private let current: Value

        fileprivate init(subject: _PassthroughSubject<Value>, current: Value) {
            self.subject = subject
            self.current = current
        }

        @discardableResult
        public func sink(receiveValue: @escaping (Value) -> Void) -> AnyCancellable {
            receiveValue(current)
            return subject.subscribe(receiveValue)
        }

        public func eraseToAnyPublisher() -> AnyPublisher<Value, Never> {
            AnyPublisher { handler in
                handler(current)
                return subject.subscribe(handler)
            }
        }
    }
}
#endif
