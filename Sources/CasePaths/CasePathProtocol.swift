public protocol _PartialCasePath<Value> {
  associatedtype Value

  func appending<AppendedValue>(
    path: some CasePathProtocol<Value, AppendedValue>
  ) -> any _PartialCasePath<AppendedValue>
}

extension _PartialCasePath {
  @inlinable
  public func appending<AppendedValue>(
    path: some CasePathProtocol<Value, AppendedValue>
  ) -> any _PartialCasePath<AppendedValue> {
    _AppendCasePath(accumulated: self, next: path)
  }
}

public protocol CasePathProtocol<Root, Value>: _PartialCasePath {
  associatedtype Root
  associatedtype Value = Value

  func embed(_ value: Value) -> Root
  func extract(from root: Root) -> Value?
}

extension CasePathProtocol {
  @inlinable
  public func appending<AppendedValue>(
    path: some CasePathProtocol<Value, AppendedValue>
  ) -> some CasePathProtocol<Root, AppendedValue> {
    _AppendCasePath(accumulated: self, next: path)
  }
}

public struct _IdentityCasePath<Root>: _PartialCasePath {
  public typealias Value = Root
  @inlinable
  public init() {}
  @inlinable
  public func embed(_ value: Value) -> Any { value }
  @inlinable
  public func extract(from root: Any) -> Root? { root as? Root }
  @inlinable
  public func appending<AppendedValue>(
    path: some CasePathProtocol<Value, AppendedValue>
  ) -> any _PartialCasePath<AppendedValue> {
    path
  }
}

extension _IdentityCasePath: CasePathProtocol {
  @inlinable
  public func embed(_ value: Root) -> Root { value }
  @inlinable
  public func extract(from root: Root) -> Root? { root }
}

public struct _AppendCasePath<
  Accumulated: _PartialCasePath, Next: CasePathProtocol
>: _PartialCasePath
where Accumulated.Value == Next.Root {
  public typealias Value = Next.Value
  public let accumulated: Accumulated
  public let next: Next
  @inlinable
  public init(accumulated: Accumulated, next: Next) {
    self.accumulated = accumulated
    self.next = next
  }
}

extension _AppendCasePath: CasePathProtocol where Accumulated: CasePathProtocol {
  @inlinable
  public func embed(_ value: Next.Value) -> Accumulated.Root {
    self.accumulated.embed(self.next.embed(value))
  }
  @inlinable
  public func extract(from root: Accumulated.Root) -> Next.Value? {
    guard
      let nextRoot = self.accumulated.extract(from: root),
      let nextValue = self.next.extract(from: nextRoot)
    else { return nil }
    return nextValue
  }
}
