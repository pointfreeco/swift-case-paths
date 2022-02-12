#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Publishers {
  public struct Extract<Upstream, Output>: Publisher where Upstream: Publisher {
    public typealias Failure = Upstream.Failure

    public let upstream: AnyPublisher<Output, Failure>

    public init(upstream: Upstream, casePath: CasePath<Upstream.Output, Output>) {
      self.upstream = upstream
        .flatMap { upstreamValue -> AnyPublisher<Output, Failure> in
          guard let extracted = casePath.extract(from: upstreamValue) else {
            return Empty().eraseToAnyPublisher()
          }
          return Just(extracted).setFailureType(to: Failure.self).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
      upstream.receive(subscriber: subscriber)
    }
  }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
  /// Extract the enum associated value from an upstream.
  ///
  /// ```swift
  /// Just(Result<Int, Error>.success(42)).extract(/Result.success) // Emits 42
  /// ```
  ///
  /// - Parameters:
  ///   - casePath: A casePath to extract the value from.
  /// - Returns: A new publisher emitting the extracted value from upstream enum value.
  public func extract<V>(_ casePath: CasePath<Self.Output, V>) -> Publishers.Extract<Self, V> {
    return Publishers.Extract(upstream: self, casePath: casePath)
  }
}
#endif
