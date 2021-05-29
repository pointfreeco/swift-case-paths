public func ~= <P>(pattern: P, value: P.Root) -> Bool where P: Path {
  pattern.extract(from: value) != nil
}

prefix operator /

public prefix func / <Root>(`case`: Root) -> CasePath<Root, Void> {
  CasePath { `case` }
}

public prefix func / <Root, Value>(embed: @escaping (Value) -> Root) -> CasePath<Root, Value> {
  CasePath(embed)
}

public prefix func / <Root, A, B>(embed: @escaping (A, B) -> Root) -> CasePath<Root, (A, B)> {
  CasePath(embed)
}

public prefix func / <Root, A, B, C>(
  embed: @escaping (A, B, C) -> Root
) -> CasePath<Root, (A, B, C)> {
  CasePath(embed)
}

public prefix func / <Root, A, B, C, D>(
  embed: @escaping (A, B, C, D) -> Root
) -> CasePath<Root, (A, B, C, D)> {
  CasePath(embed)
}

public prefix func / <Root, A, B, C, D, E>(
  embed: @escaping (A, B, C, D, E) -> Root
) -> CasePath<Root, (A, B, C, D, E)> {
  CasePath(embed)
}

public prefix func / <Root>(_: Root.Type) -> CasePath<Root, Root> {
  .self
}

public prefix func / <Root>(_: CasePath<Root, Root>) -> CasePath<Root, Root> {
  .self
}

@_disfavoredOverload
public prefix func / <Root, Value>(embed: @escaping (Value) -> Root) -> (Root) -> Value? {
  extract(embed)
}

@_disfavoredOverload
public prefix func / <Root>(root: Root) -> (Root) -> Void? {
  (/root).extract
}

precedencegroup CasePathCompositionPrecedence {
  associativity: right
}

infix operator ..: CasePathCompositionPrecedence

extension _AppendOptionalPath {
  public static func .. (lhs: Self, rhs: AnyPath) -> AnyOptionalPath?
  where Self == AnyOptionalPath { lhs.appending(path: rhs) }

  public static func .. <Root>(lhs: Self, rhs: AnyPath) -> PartialOptionalPath<Root>?
  where Self == PartialOptionalPath<Root> { lhs.appending(path: rhs) }

  public static func appending<Root, AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> OptionalPath<Root, AppendedPath.Value>?
  where Self == PartialOptionalPath<Root>, AppendedPath: Path { lhs.appending(path: rhs) }

  public static func appending<Root, AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>?
  where Self == PartialOptionalPath<Root>, AppendedPath: WritablePath { lhs.appending(path: rhs) }
}

extension Path {
  public static func .. <AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> OptionalPath<Root, AppendedPath.Value>
  where AppendedPath: Path, AppendedPath.Root == Value { lhs.appending(path: rhs) }
}

extension WritablePath {
  public static func .. <AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>
  where AppendedPath: WritablePath, AppendedPath.Root == Value { lhs.appending(path: rhs) }
}

extension WritableKeyPath {
  public static func .. <AppendedPath>(
    lhs: WritableKeyPath, rhs: AppendedPath
  ) -> WritableOptionalPath<Root, AppendedPath.Value>
  where AppendedPath: WritablePath, Value == AppendedPath.Root? { lhs.appending(path: rhs) }
}

extension EmbeddablePath {
  public static func .. <AppendedPath>(
    lhs: Self, rhs: AppendedPath
  ) -> CasePath<Root, AppendedPath.Value>
  where AppendedPath: EmbeddablePath, AppendedPath.Root == Value { lhs.appending(path: rhs) }
}
