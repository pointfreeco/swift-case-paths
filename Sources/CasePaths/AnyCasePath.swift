/// A type-erased case path that supports embedding a value in a root and attempting to extract a
/// root's embedded value.
@frozen
public struct AnyCasePath<Root, Value>: CasePath {
  @usableFromInline
  let _embed: (Value) -> Root
  @usableFromInline
  let _extract: (Root) -> Value?

  /// Creates a type-erased case path from a pair of functions.
  ///
  /// - Parameters:
  ///   - embed: A function that always succeeds in embedding a value in a root.
  ///   - extract: A function that can optionally fail in extracting a value from a root.
  @inlinable
  public init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?
  ) {
    self._embed = embed
    self._extract = extract
  }

  /// Creates a type-erased case path that wraps a given case path.
  ///
  /// - Parameter base: A case path to wrap.
  @inlinable
  public init(_ base: some CasePath<Root, Value>) {
    self.init(embed: base.embed, extract: base.extract(from:))
  }

  /// Returns a root by embedding a value.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: A root that embeds `value`.
  @inlinable
  public func embed(_ value: Value) -> Root {
    self._embed(value)
  }

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value if it can be extracted from the given root, otherwise `nil`.
  @inlinable
  public func extract(from root: Root) -> Value? {
    self._extract(root)
  }
}

extension AnyCasePath where Root == Value {
  /// The identity case path.
  ///
  /// A case path that:
  ///
  ///   * Given a value to embed, returns the given value.
  ///   * Given a value to extract, returns the given value.
  @inlinable
  public init() where Root == Value {
    self.init(embed: { $0 }, extract: { $0 })
  }
}

extension AnyCasePath: CustomDebugStringConvertible {
  public var debugDescription: String {
    "AnyCasePath<\(typeName(Root.self)), \(typeName(Value.self))>"
  }
}
