/// A type that can embed a value in a root, and attempt to extract a value from a root.
///
/// The `@CasePathable` macro generates conformances to this protocol for each of an num's cases,
/// nested in the enum's ``CasePathable/AllCasePaths`` type.
@dynamicMemberLookup
public protocol CasePath<Root, Value> {
  /// The root type that can embed and extract a ``Value``.
  associatedtype Root

  /// The value type that can be embedded in and extracted from a ``Root``.
  associatedtype Value

  /// Returns a root by embedding a value.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: A root that embeds `value`.
  func embed(_ value: Value) -> Root

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value if it can be extracted from the given root, otherwise `nil`.
  func extract(from root: Root) -> Value?
}

extension CasePath {
  /// Returns a new case path created by appending the case path at the given key path to this
  /// one.
  ///
  /// This subscript is automatically invoked by case key path expressions via dynamic member
  /// lookup, and should not be invoked directly.
  ///
  /// - Parameter keyPath: A key path to a case path.
  @inlinable
  public subscript<Appended: CasePath>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, Appended>
  ) -> _AppendCasePath<Self, Appended>
  where Value: CasePathable, Appended.Root == Value {
    _AppendCasePath(_base: self, _appended: Value.allCasePaths[keyPath: keyPath])
  }
}

@frozen
public struct _AppendCasePath<Base: CasePath, Appended: CasePath>: CasePath
where Base.Value == Appended.Root {
  @usableFromInline
  let _base: Base
  @usableFromInline
  let _appended: Appended

  @usableFromInline
  init(_base: Base, _appended: Appended) {
    self._base = _base
    self._appended = _appended
  }

  @inlinable
  public func embed(_ value: Appended.Value) -> Base.Root {
    _base.embed(_appended.embed(value))
  }

  @inlinable
  public func extract(from root: Base.Root) -> Appended.Value? {
    _base.extract(from: root).flatMap(_appended.extract(from:))
  }
}

extension _AppendCasePath: Sendable where Base: Sendable, Appended: Sendable {}
extension _AppendCasePath: Equatable where Base: Equatable, Appended: Equatable {}
extension _AppendCasePath: Hashable where Base: Hashable, Appended: Hashable {}

extension KeyPath {
  /// Returns a new case key path created by appending the given case key path to this one.
  ///
  /// Use this method to extend a case key path to a case of the value's own case-pathable type:
  ///
  /// ```swift
  /// let fooToBar = \Foo.Cases.bar
  /// let barToInt = \.int as CaseKeyPath<Bar, Bar.AllCasePaths._int>
  /// let fooToInt = fooToBar.appending(path: \.int)
  /// ```
  ///
  /// Appending a single case at a time produces a key path that is equal to, and hashes the same
  /// as, the directly spelled chain (`\Foo.Cases.bar.int`).
  ///
  /// - Parameter path: A key path to a case path of this key path's value.
  /// - Returns: A key path from the root of this key path to the value of the appended case path.
  public func appending<Appended: CasePath>(
    path: KeyPath<Value.Value.AllCasePaths, Appended>
  ) -> KeyPath<Root, _AppendCasePath<Value, Appended>>
  where Value: CasePath, Value.Value: CasePathable, Appended.Root == Value.Value {
    appending(path: \Value.[dynamicMember: path])
  }
}
