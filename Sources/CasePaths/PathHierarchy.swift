public protocol AnyPath {
  /// The root type for this path.
  static var rootType: Any.Type { get }

  /// The value type for this path.
  static var valueType: Any.Type { get }

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value iff it can be extracted from the given root, otherwise `nil`.
  func extract(from root: Any) -> Any?
}

public protocol PartialPath: AnyPath {
  associatedtype Root

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value iff it can be extracted from the given root, otherwise `nil`.
  func extract(from root: Root) -> Any?
}

public protocol Path: PartialPath {
  associatedtype Value

  /// Attempts to extract a value from a root.
  ///
  /// - Parameter root: A root to extract from.
  /// - Returns: A value iff it can be extracted from the given root, otherwise `nil`.
  func extract(from root: Root) -> Value?
}

public protocol WritablePath: Path {
  func set(into root: inout Root, _ value: Value)
}

public protocol EmbeddablePath: WritablePath {
  /// Returns a root by embedding a value.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: A root that embeds `value`.
  func embed(_ value: Value) -> Root
}

// MARK: - Key Paths

extension AnyKeyPath: AnyPath {
  @inlinable public func extract(from root: Any) -> Any? {
    root[keyPath: self]
  }
}

extension PartialKeyPath: PartialPath {
  public typealias Root = Root

  @inlinable public func extract(from root: Root) -> Any? {
    root[keyPath: self]
  }
}

extension KeyPath: Path {
  public typealias Value = Value

  @inlinable public func extract(from root: Root) -> Value? {
    root[keyPath: self]
  }
}

extension WritableKeyPath: WritablePath {
  @inlinable public func set(into root: inout Root, _ value: Value) {
    root[keyPath: self] = value
  }
}

// MARK: - Optional Paths

//public protocol _AppendOptionalPath {}
public typealias _AppendOptionalPath = _AppendKeyPath

public class AnyOptionalPath: _AppendOptionalPath, AnyPath {
  @inlinable public static var rootType: Any.Type { Self._rootAndValueType.root }

  @inlinable public static var valueType: Any.Type { Self._rootAndValueType.value }

  @usableFromInline class var _rootAndValueType: (root: Any.Type, value: Any.Type) { fatalError() }

  @usableFromInline let _extract: (Any) -> Any?

  @usableFromInline init(extract: @escaping (Any) -> Any?) {
    self._extract = extract
  }

  @_disfavoredOverload
  @inlinable public func extract(from root: Any) -> Any? {
    self._extract(root)
  }
}

extension _AppendOptionalPath {
  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending(
    path: AnyPath
  ) -> AnyOptionalPath?
  where Self == AnyOptionalPath {
    _tryToAppendOptionalPaths(root: self, leaf: path)
  }
}

public class PartialOptionalPath<Root>: AnyOptionalPath, PartialPath {
  public typealias Root = Root

  @usableFromInline init(extract: @escaping (Root) -> Any?) {
    super.init(extract: { ($0 as? Root).flatMap(extract) })
  }

  @_disfavoredOverload
  @inlinable public func extract(from root: Root) -> Any? {
    self._extract(root)
  }
}

extension _AppendOptionalPath {
  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending<Root>(
    path: AnyPath
  ) -> PartialOptionalPath<Root>?
  where Self == PartialOptionalPath<Root> {
    _tryToAppendOptionalPaths(root: self, leaf: path)
  }

  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending<Root, AppendedPath>(
    path: AppendedPath
  ) -> OptionalPath<Root, AppendedPath.Value>?
  where Self == PartialOptionalPath<Root>, AppendedPath: Path {
    _tryToAppendOptionalPaths(root: self, leaf: path)
  }

  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending<Root, AppendedPath>(
    path: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>?
  where Self == PartialOptionalPath<Root>, AppendedPath: WritablePath {
    _tryToAppendOptionalPaths(root: self, leaf: path)
  }
}

public class OptionalPath<Root, Value>: PartialOptionalPath<Root>, Path {
  public typealias Value = Value

  @usableFromInline override class var _rootAndValueType: (root: Any.Type, value: Any.Type) {
    (root: Root.self, value: Value.self)
  }

  /// Creates an optional path from an extract function.
  ///
  /// - Parameter extract: A function that attempts to extract a value from a root.
  @inlinable public init(extract: @escaping (Root) -> Value?) {
    super.init(extract: extract)
  }

  @inlinable public func extract(from root: Root) -> Value? {
    self._extract(root) as? Value
  }
}

extension Path {
  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending<AppendedPath>(
    path: AppendedPath
  ) -> OptionalPath<Root, AppendedPath.Value>
  where AppendedPath: Path, AppendedPath.Root == Value {
    func _path<P>(for path: P) -> OptionalPath<P.Root, P.Value> where P: Path {
      if let path = path as? OptionalPath<P.Root, P.Value> {
        return path
      } else {
        return OptionalPath(extract: path.extract(from:))
      }
    }
    return _appendingOptionalPaths(root: _path(for: self), leaf: _path(for: path))
  }
}

/// A path that supports setting a value in a root and attempting to extract a value from a root.
///
/// This type defines writable key path-like semantics for optional chaining.
public class WritableOptionalPath<Root, Value>: OptionalPath<Root, Value>, WritablePath {
  @usableFromInline let _set: (inout Root, Value) -> Void

  /// Creates a writable optional path from a pair of functions.
  ///
  /// - Parameters:
  ///   - extract: A function that attempts to extract a value from a root.
  ///   - embed: A function that always succeeds in setting a value on a root
  @inlinable public init(
    extract: @escaping (Root) -> Value?,
    set: @escaping (inout Root, Value) -> Void
  ) {
    self._set = set
    super.init(extract: extract)
  }

  /// "Upcasts" a writable key path to a writable optional path.
  ///
  /// - Parameter keyPath: A writable key path.
  @inlinable public convenience init(
    _ keyPath: WritableKeyPath<Root, Value?>
  ) {
    self.init(
      extract: { $0[keyPath: keyPath] },
      set: { $0[keyPath: keyPath] = $1 }
    )
  }

  @inlinable public func set(into root: inout Root, _ value: Value) {
    self._set(&root, value)
  }
}

extension WritablePath {
  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending<AppendedPath>(
    path: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>
  where AppendedPath: WritablePath, AppendedPath.Root == Value {
    func _path<P>(for path: P) -> WritableOptionalPath<P.Root, P.Value> where P: WritablePath {
      if let path = path as? WritableOptionalPath<P.Root, P.Value> {
        return path
      } else {
        return WritableOptionalPath(extract: path.extract(from:), set: path.set)
      }
    }
    return _appendingOptionalPaths(root: _path(for: self), leaf: _path(for: path))
  }
}

extension WritableKeyPath {
  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending<AppendedPath>(
    path: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>
  where AppendedPath: WritablePath, Value == AppendedPath.Root? {
    WritableOptionalPath(self).appending(path: path)
  }
}

/// A path that supports embedding a value in a root and attempting to extract a root's embedded
/// value.
///
/// This type defines key path-like semantics for enum cases.
public class CasePath<Root, Value>: WritableOptionalPath<Root, Value>, EmbeddablePath {
  @usableFromInline let _embed: (Value) -> Root

  /// Creates a case path from a pair of functions.
  ///
  /// - Parameters:
  ///   - extract: A function that attempts to extract a value from a root.
  ///   - embed: A function that always succeeds in embedding a value in a root
  @inlinable public init(
    extract: @escaping (Root) -> Value?,
    embed: @escaping (Value) -> Root
  ) {
    self._embed = embed
    super.init(extract: extract, set: { $0 = embed($1) })
  }

  /// Returns a case path that extracts values associated with a given enum case initializer.
  ///
  /// - Note: This function is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An enum case initializer.
  /// - Returns: A case path that extracts associated values from enum cases.
  @inlinable public convenience init(_ embed: @escaping (Value) -> Root) {
    self.init(extract: CasePaths.extract(embed), embed: embed)
  }

  @inlinable public func embed(_ value: Value) -> Root {
    self._embed(value)
  }
}

extension CasePath where Root == Value {
  @inlinable public static var `self`: CasePath {
    .init(extract: { $0 }, embed: { $0 })
  }
}

extension EmbeddablePath {
  /// Returns a new path created by appending the given path to this one.
  ///
  /// - Parameters:
  ///   - lhs: A path from a root to a value.
  ///   - rhs: A path from the first path's value to some other appended value.
  /// - Returns: A new path from the first path's root to the second case path's value.
  @inlinable public func appending<AppendedPath>(
    path: AppendedPath
  ) -> CasePath<Root, AppendedPath.Value>
  where AppendedPath: EmbeddablePath, AppendedPath.Root == Value {
    func _path<P>(for path: P) -> CasePath<P.Root, P.Value> where P: EmbeddablePath {
      if let path = path as? CasePath<P.Root, P.Value> {
        return path
      } else {
        return CasePath(extract: path.extract(from:), embed: path.embed)
      }
    }
    return _appendingOptionalPaths(root: _path(for: self), leaf: _path(for: path))
  }
}

@usableFromInline func _tryToAppendOptionalPaths<Result: AnyOptionalPath>(
  root: AnyPath,
  leaf: AnyPath
) -> Result? {
  func _optionalPath(_ path: AnyPath) -> AnyOptionalPath {
    if let path = path as? AnyOptionalPath { return path }
    func open<Root>(_: Root.Type) -> AnyOptionalPath {
      func open2<Value>(_: Value.Type) -> AnyOptionalPath {
        if let path = path as? WritableKeyPath<Root, Value> {
          return WritableOptionalPath(extract: path.extract(from:), set: path.set)
        } else {
          return OptionalPath(extract: (path as! KeyPath<Root, Value>).extract(from:))
        }
      }
      return _openExistential(type(of: path).valueType, do: open2)
    }
    return _openExistential(type(of: path).rootType, do: open)
  }
  let root = _optionalPath(root)
  let leaf = _optionalPath(leaf)

  let (rootRoot, rootValue) = type(of: root)._rootAndValueType
  let (leafRoot, leafValue) = type(of: leaf)._rootAndValueType

  if rootValue != leafRoot {
    return nil
  }

  func open<Root>(_: Root.Type) -> Result {
    func open2<Value>(_: Value.Type) -> Result {
      func open3<AppendedValue>(_: AppendedValue.Type) -> Result {
        let typedRoot = unsafeDowncast(root, to: OptionalPath<Root, Value>.self)
        let typedLeaf = unsafeDowncast(leaf, to: OptionalPath<Value, AppendedValue>.self)
        let result = _appendingOptionalPaths(root: typedRoot, leaf: typedLeaf)
        return unsafeDowncast(result, to: Result.self)
      }
      return _openExistential(leafValue, do: open3)
    }
    return _openExistential(rootValue, do: open2)
  }
  return _openExistential(rootRoot, do: open)
}

@usableFromInline func _appendingOptionalPaths<
  Root, Value, AppendedValue,
  Result: OptionalPath<Root, AppendedValue>
>(
  root: OptionalPath<Root, Value>,
  leaf: OptionalPath<Value, AppendedValue>
) -> Result {
  switch (root, leaf) {
  case let (root as CasePath<Root, Value>, leaf as CasePath<Value, AppendedValue>):
    return unsafeDowncast(
      CasePath<Root, AppendedValue>(
        extract: { root.extract(from: $0).flatMap(leaf.extract) },
        embed: { root.embed(leaf.embed($0)) }
      ),
      to: Result.self
    )

  case let (
    root as WritableOptionalPath<Root, Value>,
    leaf as WritableOptionalPath<Value, AppendedValue>
  ):
    return unsafeDowncast(
      WritableOptionalPath<Root, AppendedValue>(
        extract: { root.extract(from: $0).flatMap(leaf.extract) },
        set: {
          guard var value = root.extract(from: $0) else { return }
          leaf.set(into: &value, $1)
          root.set(into: &$0, value)
        }
      ),
      to: Result.self
    )

  default:
    return unsafeDowncast(
      OptionalPath<Root, AppendedValue>(
        extract: { root.extract(from: $0).flatMap(leaf.extract) }
      ),
      to: Result.self
    )
  }
}
