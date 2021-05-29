/// Returns whether or not a root value matches a particular case path.
///
///     [Result<Int, Error>.success(1), .success(2), .failure(NSError()), .success(4)]
///       .prefix(while: { /Result.success ~= $0 })
///     // [.success(1), .success(2)]
///
/// - Parameters:
///   - pattern: A case path.
///   - value: A root value.
/// - Returns: Whether or not a root value matches a particular case path
@inlinable public func ~= <P>(pattern: P, value: P.Root) -> Bool where P: Path {
  pattern.extract(from: value) != nil
}

prefix operator /

/// Returns a case path that successfully extracts `()` from a given enum case with no associated
/// values.
///
/// - Note: This function is only intended to be used with enum cases that have no associated
///   values. Its behavior is otherwise undefined.
/// - Parameter value: An enum case with no associated values.
/// - Returns: A case path that extracts `()` if the case matches, otherwise `nil`.
@inlinable public prefix func / <Root>(`case`: Root) -> CasePath<Root, Void> {
  let label = "\(`case`)"
  return CasePath(
    extract: { "\($0)" == label ? () : nil },
    embed: { `case` }
  )
}

/// Returns a case path that extracts values associated with a given enum case initializer.
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A case path that extracts associated values from enum cases.
@inlinable public prefix func / <Root, Value>(
  embed: @escaping (Value) -> Root
) -> CasePath<Root, Value> {
  CasePath(embed)
}

/// Returns a case path that extracts values associated with a given enum case initializer.
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A case path that extracts associated values from enum cases.
@inlinable public prefix func / <Root, A, B>(
  embed: @escaping (A, B) -> Root
) -> CasePath<Root, (A, B)> {
  CasePath(embed)
}

/// Returns a case path that extracts values associated with a given enum case initializer.
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A case path that extracts associated values from enum cases.
@inlinable public prefix func / <Root, A, B, C>(
  embed: @escaping (A, B, C) -> Root
) -> CasePath<Root, (A, B, C)> {
  CasePath(embed)
}

/// Returns a case path that extracts values associated with a given enum case initializer.
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A case path that extracts associated values from enum cases.
@inlinable public prefix func / <Root, A, B, C, D>(
  embed: @escaping (A, B, C, D) -> Root
) -> CasePath<Root, (A, B, C, D)> {
  CasePath(embed)
}

/// Returns a case path that extracts values associated with a given enum case initializer.
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A case path that extracts associated values from enum cases.
@inlinable public prefix func / <Root, A, B, C, D, E>(
  embed: @escaping (A, B, C, D, E) -> Root
) -> CasePath<Root, (A, B, C, D, E)> {
  CasePath(embed)
}

/// Returns the identity case path for the given type. Enables `/MyType.self` syntax.
///
/// - Parameter _: A type for which to return the identity case path.
/// - Returns: An identity case path.
@inlinable public prefix func / <Root>(_: Root.Type) -> CasePath<Root, Root> {
  .self
}

/// Identifies and returns a given case path. Enables shorthand syntax on static case paths, _e.g._
/// `/.self`  instead of `.self`.
///
/// - Parameter _: A type for which to return the identity case path.
/// - Returns: An identity case path.
@inlinable public prefix func / <Root>(_: CasePath<Root, Root>) -> CasePath<Root, Root> {
  .self
}

/// Returns a function that attempts to extract associated values from the given enum case
/// initializer.
///
/// Use this operator to create new transform functions to pass to higher-order methods like
/// `compactMap`:
///
///     [Result<Int, Error>.success(42), .failure(MyError()]
///       .compactMap(/Result.success)
///     // [42]
///
/// - Note: This operator is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A function that can attempt to extract associated values from an enum.
@_disfavoredOverload
@inlinable public prefix func / <Root, Value>(embed: @escaping (Value) -> Root) -> (Root) -> Value? {
  extract(embed)
}

/// Returns a function that attempts to identify a given enum case with no associated values.
///
/// - Note: This operator is only intended to be used with bare enum cases. Its behavior is
///   otherwise undefined.
/// - Parameter case: An enum case with no associated values.
/// - Returns: A function that attempts to identify a given enum case with no associated values.
@_disfavoredOverload
@inlinable public prefix func / <Root>(root: Root) -> (Root) -> Void? {
  (/root).extract
}

precedencegroup CasePathCompositionPrecedence {
  associativity: right
}

infix operator ..: CasePathCompositionPrecedence

extension _AppendOptionalPath {
  @inlinable public static func .. (lhs: Self, rhs: AnyPath) -> AnyOptionalPath?
  where Self == AnyOptionalPath { lhs.appending(path: rhs) }

  @inlinable public static func .. <Root>(lhs: Self, rhs: AnyPath) -> PartialOptionalPath<Root>?
  where Self == PartialOptionalPath<Root> { lhs.appending(path: rhs) }

  @inlinable public static func appending<Root, AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> OptionalPath<Root, AppendedPath.Value>?
  where Self == PartialOptionalPath<Root>, AppendedPath: Path { lhs.appending(path: rhs) }

  @inlinable public static func appending<Root, AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>?
  where Self == PartialOptionalPath<Root>, AppendedPath: WritablePath { lhs.appending(path: rhs) }
}

extension Path {
  @inlinable public static func .. <AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> OptionalPath<Root, AppendedPath.Value>
  where AppendedPath: Path, AppendedPath.Root == Value { lhs.appending(path: rhs) }
}

extension WritablePath {
  @inlinable public static func .. <AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>
  where AppendedPath: WritablePath, AppendedPath.Root == Value { lhs.appending(path: rhs) }
}

extension WritableKeyPath {
  @inlinable public static func .. <AppendedPath>(
    lhs: WritableKeyPath, rhs: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>
  where AppendedPath: WritablePath, Value == AppendedPath.Root? { lhs.appending(path: rhs) }
}

extension EmbeddablePath {
  @inlinable public static func .. <AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> CasePath<Root, AppendedPath.Value>
  where AppendedPath: EmbeddablePath, AppendedPath.Root == Value { lhs.appending(path: rhs) }
}
