import Foundation

/// A type-erased optional path that supports extracting an optional value from a root, and
/// non-optionally updating a value when present.
///
/// This type defines key path-like semantics for optional-chaining.
public struct AnyOptionalPath<Root, Value>: Sendable {
  private let _get: @Sendable (Root) -> Value?
  private let _set: @Sendable (inout Root, Value) -> Void

  /// Creates a type-erased optional path from a pair of functions.
  ///
  /// - Parameters:
  ///   - get: A function that can optionally fail in extracting a value from a root.
  ///   - set: A function that always succeeds in updating a value in a root when present.
  public init(
    get: @escaping @Sendable (Root) -> Value?,
    set: @escaping @Sendable (inout Root, Value) -> Void
  ) {
    self._get = get
    self._set = set
  }

  /// Creates a type-erased optional path from a type-erased case path.
  ///
  /// - Parameters:
  ///   - get: A function that can optionally fail in extracting a value from a root.
  ///   - set: A function that always succeeds in updating a value in a root when present.
  public init(_ casePath: AnyCasePath<Root, Value>) {
    self.init(get: casePath.extract) { $0 = casePath.embed($1) }
  }

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value if it can be extracted from the given root, otherwise `nil`.
  public func extract(from root: Root) -> Value? {
    self._get(root)
  }

  /// Returns a root by embedding a value.
  ///
  /// - Parameters:
  ///   - root: A root to modify.
  ///   - value: A value to update in the root when an existing value is present.
  public func set(into root: inout Root, _ value: Value) {
    self._set(&root, value)
  }
}

extension AnyOptionalPath where Root == Value {
  /// The identity optional path.
  ///
  /// An optional path that:
  ///
  ///   * Given a value to extract, returns the given value.
  ///   * Given a value to update, replaces the given value.
  public init() where Root == Value {
    self.init(get: { $0 }, set: { $0 = $1 })
  }
}

extension AnyOptionalPath: CustomDebugStringConvertible {
  public var debugDescription: String {
    "AnyOptionalPath<\(typeName(Root.self)), \(typeName(Value.self))>"
  }
}
