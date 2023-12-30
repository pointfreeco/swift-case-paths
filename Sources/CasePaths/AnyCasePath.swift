import Foundation

/// A type-erased case path that supports embedding a value in a root and attempting to extract a
/// root's embedded value.
///
/// This type defines key path-like semantics for enum cases, and is used to derive ``CaseKeyPath``s
/// from types that conform to ``CasePathable``.
@dynamicMemberLookup
public struct AnyCasePath<Root, Value>: CasePathProtocol {
  public let base: any CasePathProtocol<Root, Value>

  @inlinable
  public init(_ base: some CasePathProtocol<Root, Value>) {
    self.base = base
  }

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
    self.init(_ClosureCasePath(embed: embed, extract: extract))
  }

  /// Returns a root by embedding a value.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: A root that embeds `value`.
  @inlinable
  public func embed(_ value: Value) -> Root {
    self.base.embed(value)
  }

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value if it can be extracted from the given root, otherwise `nil`.
  @inlinable
  public func extract(from root: Root) -> Value? {
    self.base.extract(from: root)
  }
}

@usableFromInline
struct _ClosureCasePath<Root, Value>: CasePathProtocol {
  @usableFromInline
  let _embed: (Value) -> Root

  @usableFromInline
  let _extract: (Root) -> Value?

  @inlinable
  init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?
  ) {
    self._embed = embed
    self._extract = extract
  }

  @inlinable
  func embed(_ value: Value) -> Root {
    self._embed(value)
  }

  @inlinable
  func extract(from root: Root) -> Value? {
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
  @available(*, deprecated, message: "Initialize with an explicit path instead.")
  public init() where Root == Value {
    self.init(_IdentityCasePath())
  }
}

extension AnyCasePath: CustomDebugStringConvertible {
  public var debugDescription: String {
    "AnyCasePath<\(typeName(Root.self)), \(typeName(Value.self))>"
  }
}

#if canImport(_Concurrency) && compiler(>=5.5.2)
  extension AnyCasePath: @unchecked Sendable {}
#endif

extension AnyCasePath {
  #if swift(>=5.9)
    @available(
      iOS, deprecated: 9999,
      message: "Use 'CasePathable.modify', or 'extract' and 'embed', instead."
    )
    @available(
      macOS, deprecated: 9999,
      message: "Use 'CasePathable.modify', or 'extract' and 'embed', instead."
    )
    @available(
      tvOS, deprecated: 9999,
      message: "Use 'CasePathable.modify', or 'extract' and 'embed', instead."
    )
    @available(
      watchOS, deprecated: 9999,
      message: "Use 'CasePathable.modify', or 'extract' and 'embed', instead."
    )
    public func modify<Result>(
      _ root: inout Root,
      _ body: (inout Value) throws -> Result
    ) throws -> Result {
      guard var value = self.extract(from: root) else { throw ExtractionFailed() }
      let result = try body(&value)
      root = self.embed(value)
      return result
    }
  #else
    /// Attempts to modify a value in a root.
    ///
    /// - Parameters:
    ///   - root: A root to modify if the case path matches.
    ///   - body: A closure that can mutate the case's associated value. If the closure throws, the
    ///     root will be left unmodified.
    /// - Returns: The return value, if any, of the body closure.
    public func modify<Result>(
      _ root: inout Root,
      _ body: (inout Value) throws -> Result
    ) throws -> Result {
      guard var value = self.extract(from: root) else { throw ExtractionFailed() }
      let result = try body(&value)
      root = self.embed(value)
      return result
    }
  #endif

  #if swift(>=5.9)
    @available(iOS, deprecated: 9999, message: "Chain case key paths together, instead.")
    @available(macOS, deprecated: 9999, message: "Chain case key paths together, instead.")
    @available(tvOS, deprecated: 9999, message: "Chain case key paths together, instead.")
    @available(watchOS, deprecated: 9999, message: "Chain case key paths together, instead.")
    public func appending<AppendedValue>(
      path: AnyCasePath<Value, AppendedValue>
    ) -> AnyCasePath<Root, AppendedValue> {
      func open<P: CasePathProtocol<Root, Value>>(
        _ p: P
      ) -> AnyCasePath<Root, AppendedValue> {
        AnyCasePath<Root, AppendedValue>(p.appending(path: path))
      }
      return open(self.base)
    }
  #else
    /// Returns a new case path created by appending the given case path to this one.
    ///
    /// Use this method to extend this case path to the value type of another case path.
    ///
    /// - Parameter path: The case path to append.
    /// - Returns: A case path from the root of this case path to the value type of `path`.
    public func appending<AppendedValue>(
      path: AnyCasePath<Value, AppendedValue>
    ) -> AnyCasePath<Root, AppendedValue> {
      func open<P: CasePathProtocol<Root, Value>>(
        _ p: P
      ) -> AnyCasePath<Root, AppendedValue> {
        AnyCasePath<Root, AppendedValue>(p.appending(path: path))
      }
      return open(self.base)
    }
  #endif
}

struct ExtractionFailed: Error {}
