import Foundation

// NB: Deprecated after 1.0.0

extension CasePath {
  /// Creates a case path with a pair of functions.
  ///
  /// - Parameters:
  ///   - embed: A function that always succeeds in embedding a value in a root.
  ///   - extract: A function that can optionally fail in extracting a value from a root.
  @available(*, deprecated, message: "Use '#casePath' with a '@CasePathable' enum instead")
  public init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?
  ) {
    self.init(
      embed: {
        lock.lock()
        defer { lock.unlock() }
        return embed($0)
      },
      extract: {
        lock.lock()
        defer { lock.unlock() }
        return extract($0)
      },
      keyPaths: nil
    )
  }

  /// Returns a new case path created by appending the given case path to this one.
  ///
  /// Use this method to extend this case path to the value type of another case path.
  ///
  /// - Parameter path: The case path to append.
  /// - Returns: A case path from the root of this case path to the value type of `path`.
  @available(*, deprecated, message: "Use '#casePath' with a '@CasePathable' enum instead")
  public func appending<AppendedValue>(
    path: CasePath<Value, AppendedValue>
  ) -> CasePath<Root, AppendedValue> {
    CasePath<Root, AppendedValue>(
      embed: { self.embed(path.embed($0)) },
      extract: { self.extract(from: $0).flatMap(path.extract) },
      keyPaths: self.keyPaths.flatMap { keyPaths in path.keyPaths.map { keyPaths + $0 } }
    )
  }

  /// Returns a case path for the given embed function.
  ///
  /// - Note: This operator is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An embed function.
  /// - Returns: A case path.
  @available(*, deprecated, message: "Use '#casePath' with a '@CasePathable' enum instead")
  public init(_ embed: @escaping (Value) -> Root) {
    func open<Wrapped>(_: Wrapped.Type) -> (Root) -> Value? {
      optionalPromotedExtractHelp(unsafeBitCast(embed, to: ((Value) -> Wrapped?).self))
        as! (Root) -> Value?
    }
    let extract =
      ((_Witness<Root>.self as? _AnyOptional.Type)?.wrappedType)
      .map { _openExistential($0, do: open) }
      ?? extractHelp(embed)
    self.init(
      embed: embed,
      extract: extract
    )
  }
}

private enum _Witness<A> {}
private protocol _AnyOptional {
  static var wrappedType: Any.Type { get }
}
extension _Witness: _AnyOptional where A: _OptionalProtocol {
  static var wrappedType: Any.Type {
    A.Wrapped.self
  }
}

extension CasePath where Value == Void {
  /// Returns a void case path for a case with no associated value.
  ///
  /// - Note: This operator is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter root: A case with no an associated value.
  /// - Returns: A void case path.
  @available(*, deprecated, message: "Use '#casePath' with a '@CasePathable' enum instead")
  public init(_ root: Root) {
    func open<Wrapped>(_: Wrapped.Type) -> (Root) -> Void? {
      optionalPromotedExtractVoidHelp(unsafeBitCast(root, to: Wrapped?.self)) as! (Root) -> Void?
    }
    let extract =
      ((_Witness<Root>.self as? _AnyOptional.Type)?.wrappedType)
      .map { _openExistential($0, do: open) }
      ?? extractVoidHelp(root)
    self.init(embed: { root }, extract: extract)
  }
}

extension CasePath where Root == Value {
  /// Returns the identity case path for the given type. Enables `CasePath(MyType.self)` syntax.
  ///
  /// - Parameter type: A type for which to return the identity case path.
  /// - Returns: An identity case path.
  @available(*, deprecated, message: "Use '#casePath(\\.self)' with a '@CasePathable' enum instead")
  public init(_ type: Root.Type) {
    self = .self
  }
}

extension CasePath {
  /// Returns a case path that extracts values associated with a given enum case initializer.
  ///
  /// - Note: This function is only intended to be used with enum case initializers. Its behavior is
  ///   otherwise undefined.
  /// - Parameter embed: An enum case initializer.
  /// - Returns: A case path that extracts associated values from enum cases.
  @available(*, deprecated, message: "Use '#casePath' with a '@CasePathable' enum instead")
  public static func `case`(_ embed: @escaping (Value) -> Root) -> CasePath {
    self.init(
      embed: embed,
      extract: CasePaths.extract(embed)
    )
  }
}

extension CasePath where Value == Void {
  /// Returns a case path that successfully extracts `()` from a given enum case with no associated
  /// values.
  ///
  /// - Note: This function is only intended to be used with enum cases that have no associated
  ///   values. Its behavior is otherwise undefined.
  /// - Parameter value: An enum case with no associated values.
  /// - Returns: A case path that extracts `()` if the case matches, otherwise `nil`.
  @available(*, deprecated, message: "Use '#casePath' with a '@CasePathable' enum instead")
  public static func `case`(_ value: Root) -> CasePath {
    CasePath(
      embed: { value },
      extract: extractVoidHelp(value)
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
@available(*, deprecated, message: "Use a '@CasePathable' enum property, instead")
public func extract<Root, Value>(case embed: @escaping (Value) -> Root, from root: Root) -> Value? {
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
@available(*, deprecated, message: "Use a '@CasePathable' enum property, instead")
public func extract<Root, Value>(case embed: @escaping (Value) -> Root?, from root: Root?) -> Value?
{
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
@available(*, deprecated, message: "Use a '@CasePathable' enum property, instead")
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root) -> (Root) -> Value? {
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
@available(*, deprecated, message: "Use a '@CasePathable' enum property, instead")
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root?) -> (Root?) -> Value? {
  optionalPromotedExtractHelp(embed)
}


private let lock = NSRecursiveLock()

@available(*, deprecated, message: "Use 'CustomDebugStringConvertible.debugDescription' instead")
extension CasePath: CustomStringConvertible {
  public var description: String {
    "CasePath<\(typeName(Root.self)), \(typeName(Value.self))>"
  }
}
