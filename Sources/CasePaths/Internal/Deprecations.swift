// Deprecated after 1.0.0:

/// A type-erased case path that supports embedding a value in a root and attempting to extract a
/// root's embedded value.
///
/// This type has been renamed to ``AnyCasePath`` and is primarily employed by the
/// ``CasePathable()`` macro to derive ``CaseKeyPath``s from an enum's cases.
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
  public static func constant(_ value: Value) -> Self {
    .init(
      embed: { _ in () },
      extract: { .some(value) }
    )
  }
}

extension AnyCasePath where Value == Never {
  /// The never case path for `Root`: a case path that always fails to extract the a value of the
  /// uninhabited `Never` type.
  @available(*, deprecated)
  public static var never: Self {
    func absurd<A>(_ never: Never) -> A {}
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
      extract: Value.init(rawValue:)
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
      extract: Value.init
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
  public static func `case`(_ embed: @escaping (Value) -> Root) -> Self {
    self.init(
      embed: embed,
      extract: CasePaths.extract(embed)
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
  public static func `case`(_ value: Root) -> Self {
    Self(
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
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
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
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
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
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
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
@available(*, deprecated, message: "Use a '@CasePathable' case property, instead")
public func extract<Root, Value>(_ embed: @escaping (Value) -> Root?) -> (Root?) -> Value? {
  optionalPromotedExtractHelp(embed)
}
