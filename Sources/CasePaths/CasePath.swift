/// A path that supports embedding a value in a root and attempting to extract a root's embedded
/// value.
///
/// This type defines key path-like semantics for enum cases.
public final class CasePath<Root, Value>: PartialCasePath<Root> {
  /// Creates a case path with a pair of functions.
  ///
  /// - Parameters:
  ///   - embed: A function that always succeeds in embedding a value in a root.
  ///   - extract: A function that can optionally fail in extracting a value from a root.
  public init(embed: @escaping (Value) -> Root, extract: @escaping (Root) -> Value?) {
    super.init(embed: { embed($0 as! Value) }, extract: extract)
  }

  /// Returns a root by embedding a value.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: A root that embeds `value`.
  public func embed(_ value: Value) -> Root {
    self._embed(value) as! Root
  }

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value iff it can be extracted from the given root, otherwise `nil`.
  public func extract(from root: Root) -> Value? {
    self._extract(root) as? Value
  }

  /// Returns a new case path created by appending the given case path to this one.
  ///
  /// Use this method to extend this case path to the value type of another case path.
  ///
  /// - Parameter path: The case path to append.
  /// - Returns: A case path from the root of this case path to the value type of `path`.
  public func appending<AppendedValue>(
    path: CasePath<Value, AppendedValue>
  ) -> CasePath<Root, AppendedValue> {
    .init(
      embed: { self.embed(path.embed($0)) },
      extract: { self.extract(from: $0).flatMap(path.extract) }
    )
  }

  override class var _rootAndValueType: (root: Any.Type, value: Any.Type) {
    (root: Root.self, value: Value.self)
  }
}

/// A partially type-erased case path, from a concrete root type to any resulting value type.
public class PartialCasePath<Root>: AnyCasePath {
  init(embed: @escaping (Any) -> Root?, extract: @escaping (Root) -> Any?) {
    super.init(embed: embed, extract: { ($0 as? Root).flatMap(extract) })
  }

  @_disfavoredOverload
  public func embed(_ value: Any) -> Root? {
    self._embed(value) as? Root
  }

  @_disfavoredOverload
  public func extract(from root: Root) -> Any? {
    self._extract(root)
  }

  @_disfavoredOverload
  public override func appending(path: AnyCasePath) -> PartialCasePath<Root>? {
    guard type(of: self).valueType == type(of: path).rootType else { return nil }
    return .init(
      embed: { self.embed(path.embed($0)!) },
      extract: { self.extract(from: $0).flatMap(path.extract) }
    )
  }

  public func appending<AppendedRoot, AppendedValue>(
    path: CasePath<AppendedRoot, AppendedValue>
  ) -> CasePath<Root, AppendedValue>? {
    guard type(of: self).valueType == type(of: path).rootType else { return nil }
    return .init(
      embed: { (self.embed(path.embed($0)) as Root?)! },
      extract: { self.extract(from: $0).flatMap(path.extract) as? AppendedValue }
    )
  }
}

/// A type-erased case path, from any root type to any resulting value type.
public class AnyCasePath {
  /// The root type for this case path.
  public static var rootType: Any.Type { Self._rootAndValueType.root }

  /// The value type for this case path.
  public static var valueType: Any.Type { Self._rootAndValueType.value }

  @_disfavoredOverload
  public func embed(_ value: Any) -> Any? {
    self._embed(value)
  }

  @_disfavoredOverload
  public func extract(from root: Any) -> Any? {
    self._extract(root)
  }

  let _embed: (Any) -> Any?
  let _extract: (Any) -> Any?

  class var _rootAndValueType: (root: Any.Type, value: Any.Type) { fatalError() }

  init(embed: @escaping (Any) -> Any, extract: @escaping (Any) -> Any?) {
    self._embed = embed
    self._extract = extract
  }

  public func appending(path: AnyCasePath) -> AnyCasePath? {
    guard type(of: self).valueType == type(of: path).rootType else { return nil }
    return AnyCasePath(
      embed: { self.embed(path.embed($0)!)! },
      extract: { self.extract(from: $0).flatMap(path.extract(from:)) }
    )
  }
}
