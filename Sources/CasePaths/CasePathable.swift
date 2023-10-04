import XCTestDynamicOverlay

/// A type that provides a collection of all of its case paths.
///
/// Use the ``CasePathable()`` macro to automatically add case paths to an enum.
///
/// It is also possible, though less common, to manually conform a type to ``CasePathable``. For
/// example, the `Result` type is extended to be case-pathable with the following extension:
///
/// ```swift
/// extension Result: CasePathable {
///   public struct AllCasePaths {
///     var success: AnyCasePath<Result, Success> {
///       AnyCasePath(
///         embed: { .success($0) },
///         extract: {
///           guard case let .success(value) = $0 else { return nil }
///           return value
///         }
///       )
///     }
///
///     var failure: CasePath<Result, Failure> {
///       AnyCasePath(
///         embed: { .failure($0) },
///         extract: {
///           guard case let .failure(value) = $0 else { return nil }
///           return value
///         }
///       )
///     }
///   }
///
///   public static var allCasePaths: AllCasePaths { AllCasePaths() }
/// }
/// ```
public protocol CasePathable {
  /// A type that can represent a collection of all case paths of this type.
  associatedtype AllCasePaths

  /// A collection of all case paths of this type.
  static var allCasePaths: AllCasePaths { get }
}

/// A key path to the associated value of an enum case.
///
/// The most common way to make an instance of this type is by applying the ``CasePathable()`` macro
/// to an enum and using a key path expression like `\SomeEnum.Cases.someCase`, or simply
/// `\.someCase` where the type can be inferred.
///
/// To extract an associated value from an enum using a case key path, pass the key path to the
/// ``CasePathable/subscript(keyPath:)-9s97`` subscript. For example:
///
/// ```swift
/// @CasePathable
/// struct SomeEnum {
///   case someCase(Int)
///   case anotherCase(String)
/// }
///
/// let e = SomeEnum.someCase(12)
/// let pathToCase = \SomeEnum.Cases.someCase
///
/// let value = e[keyPath: pathToCase]
/// // value is Optional(12)
///
/// let anotherValue = e[keyPath: \.anotherCase]
/// // anotherValue is nil
/// ```
///
/// To replace an associated value, assign it through the ``CasePathable/subscript(keyPath:)-9s97``.
/// subscript. If the given path does not match the given enum case, the replacement will fail. For
/// example:
///
/// ```swift
/// var e = SomeEnum.someCase(12)
///
/// e[keyPath: \.someCase] = 24
/// // e is SomeEnum.someCase(24)
///
/// e[keyPath: \.anotherCase] = "Hello!"
/// // Assignment fails: e is still SomeEnum.someCase(24)
/// ```
///
/// To produce a whole instance from a case key path, call ``Swift/KeyPath/callAsFunction(_:)`` with
/// the associated value you'd like to embed:
///
/// ```swift
/// let pathToCase = \SomeEnum.Cases.someCase
///
/// let e = pathToCase(12)
/// // e is SomeEnum.someCase(12)
/// ```
///
/// The path can contain multiple case names, separated by periods, to refer to a case of a case's
/// value. This code uses the key path expression `\OuterEnum.Cases.outer.someCase` to access the
/// `someCase` associated value of the `OuterEnum` type's `outer` case:
///
/// ```swift
/// @CasePathable
/// enum OuterEnum {
///   case outer(SomeEnum)
/// }
///
/// var nested = OuterEnum.outer(.someCase(24))
/// let nestedCaseKeyPath = \OuterEnum.Cases.outer.someCase
///
/// let nestedValue = nested[keyPath: nestedCaseKeyPath]
/// // nestedValue is Optional(24)
///
/// nested[keyPath: \.outer.someCase] = 42
/// // nested is now OuterEnum.outer(.someCase(42))
/// ```
///
/// Key paths have the identity key path `\SomeStructure.self`, and so case key paths have the
/// identity case key path `\SomeEnum.Cases.self`. It refers to the whole enum and can be passed to
/// a function that takes case key paths when you want to extract, change, or replace all of the
/// data stored in an enum in a single step.
///
/// Because the ``CasePathable()`` macro produces a property to the data for each enum case, you can
/// use a key path expression in the same contexts you can use them for any property. Specifically,
/// you can use a key path expression whose root type is `SomeEnum` and whose path extracts a value
/// of type `Value?`, instead of a function or closure of type `(SomeEnum) -> Value?`.
///
/// ```swift
/// let values: SomeEnum = [
///   .someCase(12),
///   .anotherCase("Goodbye!"),
///   .someCase(30),
/// ]
///
/// // The approaches below are all equivalent.
/// values.compactMap(\.someCase).reduce(+)
/// values.compactMap { $0.someCase }.reduce(+)
/// values.compactMap { if case let .someCase(int) { int } else { nil } }.reduce(+)
/// ```
public typealias CaseKeyPath<Root, Value> = KeyPath<
  AnyCasePath<Root, Root>, AnyCasePath<Root, Value>
>

extension CaseKeyPath {
  /// Embeds a value in an enum at this case key path's case.
  ///
  /// Given a case key path to an enum case, one can produce a whole new root value to that case by
  /// invoking the key path like a function with an associated value to embed. For example:
  ///
  /// ```swift
  /// @CasePathable
  /// enum SomeEnum {
  ///   case someCase(Int)
  /// }
  ///
  /// let path = \SomeEnum.Cases.someCase
  ///
  /// let e = path(12)
  /// // e is SomeEnum.someCase(12)
  /// ```
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: An enum for the case of this key path that holds the given value.
  public func callAsFunction<Enum, AssociatedValue>(_ value: AssociatedValue) -> Enum
  where Root == AnyCasePath<Enum, Enum>, Value == AnyCasePath<Enum, AssociatedValue> {
    AnyCasePath(self).embed(value)
  }
  
  /// Returns an enum for this case key path's case.
  ///
  /// Given a case key path to an enum case with no associated value, one can produce a whole new
  /// root value to that case by invoking the key path like a function. For example:
  ///
  /// ```swift
  /// @CasePathable
  /// enum SomeEnum {
  ///   case someCase
  /// }
  ///
  /// let path = \SomeEnum.Cases.someCase
  ///
  /// let e = path()
  /// // e is SomeEnum.someCase
  /// ```
  ///
  /// - Returns: An enum for the case of this key path.
  public func callAsFunction<Enum>() -> Enum
  where Root == AnyCasePath<Enum, Enum>, Value == AnyCasePath<Enum, Void> {
    AnyCasePath(self).embed(())
  }
}

extension CasePathable {
  /// A namespace that can be used to derive case key paths from case-pathable enums.
  ///
  /// One can fully-qualify a ``CaseKeyPath`` for a type conforming to ``CasePathable`` through this
  /// namespace. For example:
  ///
  /// ```swift
  /// @CasePathable
  /// enum SomeEnum {
  ///   case someCase(Int)
  /// }
  ///
  /// \SomeEnum.Cases.someCase  // CaseKeyPath<SomeEnum, Int>
  /// ```
  public typealias Cases = AnyCasePath<Self, Self>

  /// Attempts to extract the associated value from a root enum using a case key path.
  ///
  /// For example:
  ///
  /// ```swift
  /// @CasePathable
  /// enum SomeEnum {
  ///   case someCase(Int)
  ///   case anotherCase(String)
  /// }
  ///
  /// let e = SomeEnum.someCase(12)
  ///
  /// e[keyPath: \.someCase]     // Optional(12)
  /// e[keyPath: \.anotherCase]  // nil
  /// ```
  ///
  /// See ``CasePathable/subscript(keyPath:)-9s97`` for replacing an associated value in a root
  /// enum, and see ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a
  /// brand new root enum.
  public subscript<Value>(keyPath keyPath: CaseKeyPath<Self, Value>) -> Value? {
    AnyCasePath(keyPath).extract(from: self)
  }

  /// Attempts to replace the associated value of a root enum using a case key path.
  ///
  /// For example:
  ///
  /// ```swift
  /// @CasePathable
  /// enum SomeEnum {
  ///   case someCase(Int)
  ///   case anotherCase(String)
  /// }
  ///
  /// var e = SomeEnum.someCase(12)
  ///
  /// e[keyPath: \.someCase] = 24
  /// // e is SomeEnum.someCase(24)
  ///
  /// e[keyPath: \.anotherCase] = "Hello!"
  /// // Assignment fails: e is still SomeEnum.someCase(24)
  /// ```
  ///
  /// See ``CasePathable/subscript(keyPath:)-7o5xj`` for extracting an associated value from a root
  /// enum, and see ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a
  /// brand new root enum.
  @_disfavoredOverload
  public subscript<Value>(keyPath keyPath: CaseKeyPath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let `case` = AnyCasePath(keyPath)
      guard `case`.extract(from: self) != nil else { return }
      self = `case`.embed(newValue)
    }
  }
  
  /// Unwraps and yields a mutable associated value to a closure.
  ///
  /// > Warning: If the enum's case does not match the given case key path, the mutation will not be
  /// > applied, and a runtime warning will be logged. To suppress these warnings, limit calls to
  /// > `modify` to instances in which you have already checked the enum case. For example:
  /// >
  /// > ```swift
  /// > switch e {
  /// > case .someCase:
  /// >   e.modify(\.someCase) { int in
  /// >     int += 1
  /// >   }
  /// > case .anotherCase:
  /// >   e.modify(\.anotherCase) { string in
  /// >     string.append("!")
  /// >   }
  /// > }
  /// > ```
  ///
  /// - Parameters:
  ///   - keyPath: A case key path to an associated value.
  ///   - yield: A closure given mutable access to that associated value.
  public mutating func modify<Value>(
    _ keyPath: CaseKeyPath<Self, Value>,
    yield: (inout Value) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let `case` = AnyCasePath(keyPath)
    guard var value = `case`.extract(from: self) else {
      XCTFail("Can't modify \(self) with case key path \(keyPath)", file: file, line: line)
      return
    }
    yield(&value)
    self = `case`.embed(value)
  }
}

extension AnyCasePath {
  /// Creates a type-erased case path for given case key path.
  ///
  /// - Parameter keyPath: A case key path.
  public init(_ keyPath: CaseKeyPath<Root, Value>) {
    self = AnyCasePath<Root, Root>()[keyPath: keyPath]
  }
}

extension AnyCasePath where Value: CasePathable {
  /// Returns a new case path created by appending the case path at the given key path to this one.
  ///
  /// This subscript is automatically invoked by case key path expressions via dynamic member
  /// lookup, and should not be invoked directly.
  ///
  /// - Parameter keyPath: A key path to a case-pathable case path.
  public subscript<AppendedValue>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, AppendedValue>>
  ) -> AnyCasePath<Root, AppendedValue> {
    AnyCasePath<Root, AppendedValue>(
      embed: { self.embed(Value.allCasePaths[keyPath: keyPath].embed($0)) },
      extract: {
        self.extract(from: $0).flatMap(Value.allCasePaths[keyPath: keyPath].extract(from:))
      }
    )
  }
}
