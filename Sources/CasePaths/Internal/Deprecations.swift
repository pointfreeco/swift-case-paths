@_spi(CurrentTestCase) import XCTestDynamicOverlay

#if canImport(ObjectiveC)
  import ObjectiveC
#endif

extension AnyCasePath {
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

  @available(iOS, deprecated: 9999, message: "Chain case key paths together, instead.")
  @available(macOS, deprecated: 9999, message: "Chain case key paths together, instead.")
  @available(tvOS, deprecated: 9999, message: "Chain case key paths together, instead.")
  @available(watchOS, deprecated: 9999, message: "Chain case key paths together, instead.")
  public func appending<AppendedValue>(
    path: AnyCasePath<Value, AppendedValue>
  ) -> AnyCasePath<Root, AppendedValue> {
    AnyCasePath<Root, AppendedValue>(
      embed: { self.embed(path.embed($0)) },
      extract: { self.extract(from: $0).flatMap(path.extract) }
    )
  }
}

struct ExtractionFailed: Error {}

// Deprecated after 1.4.2:

extension AnyCasePath where Root == Value {
  @available(*, deprecated, message: "Use the '\\.self' case key path, instead")
  public static var `self`: Self {
    .init(
      embed: { $0 },
      extract: { .some($0) }
    )
  }
}

extension AnyCasePath where Root: _OptionalProtocol, Value == Root.Wrapped {
  @available(*, deprecated, message: "Use the '\\Optional.Cases.some' case key path, instead")
  public static var some: Self {
    .init(embed: { Root($0) }, extract: { $0.optional })
  }
}

@_documentation(visibility: private)
public protocol _OptionalProtocol {
  associatedtype Wrapped
  var optional: Wrapped? { get }
  init(_ some: Wrapped)
}

@_documentation(visibility: private)
extension Optional: _OptionalProtocol {
  public var optional: Wrapped? { self }
}

extension AnyCasePath {
  @available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
  public init(_ embed: @escaping (Value) -> Root) {
    @UncheckedSendable var embed = embed
    self.init(unsafe: { [$embed] in $embed.wrappedValue($0) })
  }
}

extension AnyCasePath where Value == Void {
  @available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
  @_disfavoredOverload
  public init(_ root: @autoclosure @escaping @Sendable () -> Root) {
    self.init(unsafe: root())
  }
}

extension AnyCasePath where Root == Value {
  @available(*, deprecated, message: "Use the '\\.self' case key path, instead")
  public init(_ type: Root.Type) {
    self = .self
  }
}

prefix operator /

extension AnyCasePath {
  @_documentation(visibility: internal)
  @available(*, deprecated, message: "Use 'CasePathable.is' with a case key path, instead")
  public static func ~= (pattern: AnyCasePath, value: Root) -> Bool {
    pattern.extract(from: value) != nil
  }
}

@_documentation(visibility: internal)
@available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
public prefix func / <Root, Value>(
  embed: @escaping (Value) -> Root
) -> AnyCasePath<Root, Value> {
  @UncheckedSendable var embed = embed
  return AnyCasePath(
    embed: { [$embed] in $embed.wrappedValue($0) },
    extract: { [$embed] in extractHelp { $embed.wrappedValue($0) }($0) }
  )
}

@_documentation(visibility: internal)
@available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
public prefix func / <Root, Value>(
  embed: @escaping (Value) -> Root?
) -> AnyCasePath<Root?, Value> {
  @UncheckedSendable var embed = embed
  return AnyCasePath(
    embed: { [$embed] in $embed.wrappedValue($0) },
    extract: optionalPromotedExtractHelp { [$embed] in $embed.wrappedValue($0) }
  )
}

@_documentation(visibility: internal)
@available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
public prefix func / <Root>(
  root: @autoclosure @escaping @Sendable () -> Root
) -> AnyCasePath<Root, Void> {
  .init(embed: root, extract: extractVoidHelp(root()))
}

@_documentation(visibility: internal)
@available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
public prefix func / <Root>(
  root: @autoclosure @escaping @Sendable () -> Root?
) -> AnyCasePath<Root?, Void> {
  .init(embed: root, extract: optionalPromotedExtractVoidHelp(root()))
}

@_documentation(visibility: internal)
@available(*, deprecated, message: "Use the '\\.self' case key path, instead")
public prefix func / <Root>(
  type: Root.Type
) -> AnyCasePath<Root, Root> {
  .self
}

@_documentation(visibility: internal)
@available(*, deprecated, message: "Use a case key path (like '\\.self' or '\\.some'), instead")
public prefix func / <Root, Value>(
  path: AnyCasePath<Root, Value>
) -> AnyCasePath<Root, Value> {
  path
}

@_disfavoredOverload
@_documentation(visibility: internal)
@available(
  *, deprecated, message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
)
public prefix func / <Root, Value>(
  embed: @escaping (Value) -> Root
) -> (Root) -> Value? {
  (/embed).extract(from:)
}

@_disfavoredOverload
@_documentation(visibility: internal)
@available(
  *, deprecated, message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
)
public prefix func / <Root, Value>(
  embed: @escaping (Value) -> Root?
) -> (Root?) -> Value? {
  (/embed).extract(from:)
}

@_disfavoredOverload
@_documentation(visibility: internal)
@available(
  *, deprecated, message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
)
public prefix func / <Root>(
  root: @autoclosure @escaping @Sendable () -> Root
) -> (Root) -> Void? {
  (/root).extract(from:)
}

@_disfavoredOverload
@_documentation(visibility: internal)
@available(
  *, deprecated, message: "Use a 'CasePathable' case property via dynamic member lookup, instead"
)
public prefix func / <Root>(
  root: @autoclosure @escaping @Sendable () -> Root
) -> (Root?) -> Void? {
  (/root).extract(from:)
}

precedencegroup CasePathCompositionPrecedence {
  associativity: left
}

infix operator .. : CasePathCompositionPrecedence

extension AnyCasePath {
  @_documentation(visibility: internal)
  @available(*, deprecated, message: "Append 'CasePathable' case key paths, instead")
  public static func .. <AppendedValue>(
    lhs: AnyCasePath,
    rhs: AnyCasePath<Value, AppendedValue>
  ) -> AnyCasePath<Root, AppendedValue> {
    lhs.appending(path: rhs)
  }

  @_documentation(visibility: internal)
  @available(*, deprecated, message: "Append 'CasePathable' case key paths, instead")
  public static func .. <AppendedValue>(
    lhs: AnyCasePath,
    rhs: @escaping (AppendedValue) -> Value
  ) -> AnyCasePath<Root, AppendedValue> {
    lhs.appending(path: /rhs)
  }
}

@_documentation(visibility: internal)
@available(*, deprecated, message: "Chain 'CasePathable' case properties, instead")
public func .. <Root, Value, AppendedValue>(
  lhs: @escaping (Root) -> Value?,
  rhs: @escaping (AppendedValue) -> Value
) -> (Root) -> AppendedValue? {
  return { root in lhs(root).flatMap((/rhs).extract(from:)) }
}

@available(
  *, deprecated, message: "Use XCTest's 'XCTUnwrap' with a 'CasePathable' case property, instead"
)
public func XCTUnwrap<Enum, Case>(
  _ enum: @autoclosure () throws -> Enum,
  case extract: (Enum) -> Case?,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) throws -> Case {
  let `enum` = try `enum`()
  guard let value = extract(`enum`)
  else {
    #if canImport(ObjectiveC)
      _ = XCTCurrentTestCase?.perform(Selector(("setContinueAfterFailure:")), with: false)
    #endif
    let message = message()
    XCTFail(
      """
      XCTUnwrap: Expected to extract value of type "\(typeName(Case.self))" from \
      "\(typeName(Enum.self))"\
      \(message.isEmpty ? "" : " - " + message) …

        Actual:
          \(String(describing: `enum`))
      """,
      file: file,
      line: line
    )
    throw UnwrappingCase()
  }
  return value
}

@available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
public func XCTModify<Enum, Case>(
  _ enum: inout Enum,
  case casePath: AnyCasePath<Enum, Case>,
  _ message: @autoclosure () -> String = "",
  _ body: (inout Case) throws -> Void,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  _XCTModify(&`enum`, case: casePath, message(), body, file: file, line: line)
}

// Deprecated after 1.0.0:

/// A type-erased case path that supports embedding a value in a root and attempting to extract a
/// root's embedded value.
///
/// This type has been renamed to `AnyCasePath` and is primarily employed by the ``CasePathable()``
/// macro to derive `CaseKeyPath`s from an enum's cases.
@available(*, deprecated, renamed: "AnyCasePath")
public typealias CasePath = AnyCasePath

@available(*, deprecated, message: "Use 'CustomDebugStringConvertible.debugDescription', instead")
extension AnyCasePath: CustomStringConvertible {
  public var description: String {
    "AnyCasePath<\(typeName(Root.self)), \(typeName(Value.self))>"
  }
}

extension AnyCasePath where Root == Void {
  /// Returns a case path that always successfully extracts the given constant value.
  ///
  /// - Parameter value: A constant value.
  /// - Returns: A case path from `()` to `value`.
  @available(*, deprecated)
  public static func constant(_ value: @autoclosure @escaping @Sendable () -> Value) -> Self {
    .init(
      embed: { _ in () },
      extract: { .some(value()) }
    )
  }
}

extension AnyCasePath where Value == Never {
  /// The never case path for `Root`: a case path that always fails to extract the a value of the
  /// uninhabited `Never` type.
  @available(*, deprecated)
  public static var never: Self {
    @Sendable func absurd<A>(_ never: Never) -> A {}
    return .init(
      embed: absurd,
      extract: { _ in nil }
    )
  }
}

extension AnyCasePath where Value: RawRepresentable, Root == Value.RawValue {
  /// Returns a case path for `RawRepresentable` types: a case path that attempts to extract a value
  /// that can be represented by a raw value from a raw value.
  @available(*, deprecated)
  public static var rawValue: Self {
    .init(
      embed: { $0.rawValue },
      extract: { Value(rawValue: $0) }
    )
  }
}

extension AnyCasePath where Value: LosslessStringConvertible, Root == String {
  /// Returns a case path for `LosslessStringConvertible` types: a case path that attempts to
  /// extract a value that can be represented by a lossless string from a string.
  @available(*, deprecated)
  public static var description: Self {
    .init(
      embed: { $0.description },
      extract: { Value($0) }
    )
  }
}

// Deprecated after 0.5.0:

extension AnyCasePath {
  /// Returns a case path that extracts values associated with a given enum case initializer.
  ///
  /// - Note: This function is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An enum case initializer.
  /// - Returns: A case path that extracts associated values from enum cases.
  @available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
  public static func `case`(_ embed: @escaping @Sendable (Value) -> Root) -> Self {
    self.init(
      embed: embed,
      extract: { CasePaths.extract(embed)($0) }
    )
  }
}

extension AnyCasePath where Value == Void {
  /// Returns a case path that successfully extracts `()` from a given enum case with no associated
  /// values.
  ///
  /// - Note: This function is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter value: An enum case with no associated values.
  /// - Returns: A case path that extracts `()` if the case matches, otherwise `nil`.
  @available(*, deprecated, message: "Use a 'CasePathable' case key path, instead")
  public static func `case`(_ value: @autoclosure @escaping @Sendable () -> Root) -> Self {
    Self(
      embed: value,
      extract: extractVoidHelp(value())
    )
  }
}

/// Attempts to extract values associated with a given enum case initializer from a given root enum.
///
/// ```swift
/// extract(case: Result<Int, Error>.success, from: .success(42))
/// // 42
/// extract(case: Result<Int, Error>.success, from: .failure(MyError())
/// // nil
/// ```
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameters:
///   - embed: An enum case initializer.
///   - root: A root enum value.
/// - Returns: Values if they can be extracted from the given enum case initializer and root enum,
///   otherwise `nil`.
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
public func extract<Root, Value>(
  case embed: @escaping @Sendable (Value) -> Root,
  from root: Root
) -> Value? {
  CasePaths.extract(embed)(root)
}

/// Attempts to extract values associated with a given enum case initializer from a given root enum.
///
/// ```swift
/// extract(case: Result<Int, Error>.success, from: .success(42))
/// // 42
/// extract(case: Result<Int, Error>.success, from: .failure(MyError())
/// // nil
/// ```
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameters:
///   - embed: An enum case initializer.
///   - root: A root enum value.
/// - Returns: Values if they can be extracted from the given enum case initializer and root enum,
///   otherwise `nil`.
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
public func extract<Root, Value>(
  case embed: @escaping @Sendable (Value) -> Root?,
  from root: Root?
) -> Value? {
  CasePaths.extract(embed)(root)
}

/// Returns a function that can attempt to extract associated values from the given enum case
/// initializer.
///
/// Use this function to create new transform functions to pass to higher-order methods like
/// `compactMap`:
///
/// ```swift
/// [Result<Int, Error>.success(42), .failure(MyError()]
///   .compactMap(extract(Result.success))
/// // [42]
/// ```
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A function that can attempt to extract associated values from an enum.
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
public func extract<Root, Value>(_ embed: @escaping @Sendable (Value) -> Root) -> (Root) -> Value? {
  extractHelp(embed)
}

/// Returns a function that can attempt to extract associated values from the given enum case
/// initializer.
///
/// Use this function to create new transform functions to pass to higher-order methods like
/// `compactMap`:
///
/// ```swift
/// [Result<Int, Error>.success(42), .failure(MyError()]
///   .compactMap(extract(Result.success))
/// // [42]
/// ```
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter embed: An enum case initializer.
/// - Returns: A function that can attempt to extract associated values from an enum.
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
public func extract<Root, Value>(
  _ embed: @escaping @Sendable (Value) -> Root?
) -> @Sendable (Root?) -> Value? {
  optionalPromotedExtractHelp(embed)
}
