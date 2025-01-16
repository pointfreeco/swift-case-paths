import Foundation

/// A type-erased case path that supports embedding a value in a root and attempting to extract a
/// root's embedded value.
///
/// This type defines key path-like semantics for enum cases, and is used to derive ``CaseKeyPath``s
/// from types that conform to ``CasePathable``.
@dynamicMemberLookup
public struct AnyCasePath<Root, Value>: Sendable {
  private let _embed: @Sendable (Value) -> Root
  private let _extract: @Sendable (Root) -> Value?

  /// Creates a type-erased case path from a pair of functions.
  ///
  /// - Parameters:
  ///   - embed: A function that always succeeds in embedding a value in a root.
  ///   - extract: A function that can optionally fail in extracting a value from a root.
  public init(
    embed: @escaping @Sendable (Value) -> Root,
    extract: @escaping @Sendable (Root) -> Value?
  ) {
    self._embed = embed
    self._extract = extract
  }

  public static func _$embed(
    _ embed: @escaping (Value) -> Root,
    extract: @escaping @Sendable (Root) -> Value?
  ) -> Self {
    #if swift(>=5.10)
      nonisolated(unsafe) let embed = embed
      return Self(embed: { embed($0) }, extract: extract)
    #else
      @UncheckedSendable var embed = embed
      return Self(embed: { [$embed] in $embed.wrappedValue($0) }, extract: extract)
    #endif
  }

  /// Returns a root by embedding a value.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: A root that embeds `value`.
  public func embed(_ value: Value) -> Root {
    self._embed(value)
  }

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value if it can be extracted from the given root, otherwise `nil`.
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
  public init() where Root == Value {
    self.init(embed: { $0 }, extract: { $0 })
  }
}

extension AnyCasePath: CustomDebugStringConvertible {
  public var debugDescription: String {
    "AnyCasePath<\(typeName(Root.self)), \(typeName(Value.self))>"
  }
}
