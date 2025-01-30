import IssueReporting

/// A type that provides a collection of all of its case paths.
///
/// Use the `@CasePathable` macro to automatically add case paths, and this conformance, to an enum.
///
/// It is also possible, though less common, to manually conform a type to `CasePathable`. For
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
///     var failure: AnyCasePath<Result, Failure> {
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

/// A type that is used to distinguish case key paths from key paths by wrapping the enum and
/// associated value types.
@_documentation(visibility: internal)
@dynamicMemberLookup
public struct Case<Value>: Sendable {
  fileprivate let _embed: @Sendable (Value) -> Any
  fileprivate let _extract: @Sendable (Any) -> Value?
}

extension Case {
  public init<Root>(
    embed: @escaping @Sendable (Value) -> Root,
    extract: @escaping @Sendable (Root) -> Value?
  ) {
    self._embed = embed
    self._extract = { @Sendable in ($0 as? Root).flatMap(extract) }
  }

  public init() {
    self.init(embed: { $0 }, extract: { $0 })
  }

  public init<Root>(_ keyPath: CaseKeyPath<Root, Value>) {
    self = Case<Root>()[keyPath: keyPath]
  }

  public subscript<AppendedValue>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, AppendedValue>>
  ) -> Case<AppendedValue>
  where Value: CasePathable {
    let keyPath = keyPath.unsafeSendable()
    return Case<AppendedValue>(
      embed: {
        _embed(Value.allCasePaths[keyPath: keyPath].embed($0))
      },
      extract: {
        _extract(from: $0).flatMap(Value.allCasePaths[keyPath: keyPath].extract)
      }
    )
  }

  public func _embed(_ value: Value) -> Any {
    self._embed(value)
  }

  public func _extract(from root: Any) -> Value? {
    self._extract(root)
  }
}

private protocol _AnyCase {
  func extractAny(from root: Any) -> Any?
}

extension Case: _AnyCase {
  fileprivate func extractAny(from root: Any) -> Any? {
    self._extract(from: root)
  }
}

/// A key path to the associated value of an enum case.
///
/// The most common way to make an instance of this type is by applying the `@CasePathable` macro
/// to an enum and using a key path expression like `\SomeEnum.Cases.someCase`, or simply
/// `\.someCase` where the type can be inferred.
///
/// To extract an associated value from an enum using a case key path, pass the key path to the
/// ``CasePathable/subscript(case:)-3yqx3``. For example:
///
/// ```swift
/// @CasePathable
/// enum SomeEnum {
///   case someCase(Int)
///   case anotherCase(String)
/// }
///
/// let e = SomeEnum.someCase(12)
/// let pathToCase = \SomeEnum.Cases.someCase
///
/// let value = e[case: pathToCase]
/// // value is Optional(12)
///
/// let anotherValue = e[case: \.anotherCase]
/// // anotherValue is nil
/// ```
///
/// To replace an associated value, assign it through ``CasePathable/subscript(case:)-2t4f8``. If
/// the given path does not match the given enum case, the replacement will fail. For
/// example:
///
/// ```swift
/// var e = SomeEnum.someCase(12)
///
/// e[case: \.someCase] = 24
/// // e is SomeEnum.someCase(24)
///
/// e[case: \.anotherCase] = "Hello!"
/// // Assignment fails: e is still SomeEnum.someCase(24)
/// ```
///
/// To produce a whole instance from a case key path, call the key path directly with the associated
/// value you'd like to embed (via ``Swift/KeyPath/callAsFunction(_:)``):
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
/// let nestedValue = nested[case: nestedCaseKeyPath]
/// // nestedValue is Optional(24)
///
/// nested[case: \.outer.someCase] = 42
/// // nested is now OuterEnum.outer(.someCase(42))
/// ```
///
/// Key paths have the identity key path `\SomeStructure.self`, and so case key paths have the
/// identity case key path `\SomeEnum.Cases.self`. It refers to the whole enum and can be passed to
/// a function that takes case key paths when you want to extract, change, or replace all of the
/// data stored in an enum in a single step.
public typealias CaseKeyPath<Root, Value> = KeyPath<Case<Root>, Case<Value>>

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
  /// See ``Swift/KeyPath/callAsFunction()`` for cases with no associated values.
  ///
  /// - Parameter value: A value to embed.
  /// - Returns: An enum for the case of this key path that holds the given value.
  public func callAsFunction<Enum, AssociatedValue>(_ value: AssociatedValue) -> Enum
  where Root == Case<Enum>, Value == Case<AssociatedValue> {
    Case(self)._embed(value) as! Enum
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
  /// See ``Swift/KeyPath/callAsFunction(_:)`` for cases with associated values.
  ///
  /// - Returns: An enum for the case of this key path.
  public func callAsFunction<Enum>() -> Enum
  where Root == Case<Enum>, Value == Case<Void> {
    Case(self)._embed(()) as! Enum
  }

  /// Whether an argument matches the case key path's case.
  ///
  /// ```swift
  /// @CasePathable enum UserAction {
  ///   case settings(SettingsAction)
  /// }
  /// @CasePathable enum SettingsAction {
  ///   case store(StoreAction)
  /// }
  /// @CasePathable enum StoreAction {
  ///   case subscribeButtonTapped
  /// }
  ///
  /// switch userAction {
  /// case \.settings.store.subscribeButtonTapped:
  /// // ...
  /// }
  ///
  /// // Equivalent to:
  ///
  /// switch userAction {
  /// case .settings(.store(.subscribeButtonTapped)):
  /// // ...
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - lhs: A case key path.
  ///   - rhs: An enum.
  public static func ~= <Enum: CasePathable, AssociatedValue>(lhs: KeyPath, rhs: Enum) -> Bool
  where Root == Case<Enum>, Value == Case<AssociatedValue> {
    rhs[case: lhs] != nil
  }
}

/// A partially type-erased key path, from a concrete root enum to any resulting value type.
public typealias PartialCaseKeyPath<Root> = PartialKeyPath<Case<Root>>

extension _AppendKeyPath {
  /// Attempts to embeds any value in an enum at this case key path's case.
  ///
  /// - Parameter value: A value to embed. If the value type does not match the case path's value
  ///   type, the operation will fail.
  /// - Returns: An enum for the case of this key path that holds the given value, or `nil`.
  @_disfavoredOverload
  public func callAsFunction<Enum: CasePathable>(
    _ value: Any
  ) -> Enum?
  where Self == PartialCaseKeyPath<Enum> {
    func open<AnyAssociatedValue>(_ value: AnyAssociatedValue) -> Enum? {
      (Case<Enum>()[keyPath: self] as? Case<AnyAssociatedValue>)?._embed(value) as? Enum
        ?? (Case<Enum>()[keyPath: self] as? Case<AnyAssociatedValue?>)?._embed(value) as? Enum
    }
    return _openExistential(value, do: open)
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
  public typealias Cases = Case<Self>

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
  /// e[case: \.someCase]     // Optional(12)
  /// e[case: \.anotherCase]  // nil
  /// ```
  ///
  /// See ``CasePathable/subscript(case:)-2t4f8`` for replacing an associated value in a root
  /// enum, and see ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a
  /// brand new root enum.
  public subscript<Value>(case keyPath: CaseKeyPath<Self, Value>) -> Value? {
    Case(keyPath)._extract(from: self)
  }

  /// Attempts to extract the associated value from a root enum using a partial case key path.
  @_disfavoredOverload
  public subscript(case keyPath: PartialCaseKeyPath<Self>) -> Any? {
    (Case<Self>()[keyPath: keyPath] as? any _AnyCase)?.extractAny(from: self)
  }

  /// Replaces the associated value of a root enum at a case key path when the case matches.
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
  /// e[case: \.someCase] = 24
  /// // e is SomeEnum.someCase(24)
  ///
  /// e[case: \.anotherCase] = "Hello!"
  /// // e is still SomeEnum.someCase(24)
  /// ```
  ///
  /// See ``CasePathable/subscript(case:)-3yqx3`` for extracting an associated value from a root
  /// enum, and see ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a
  /// brand new root enum.
  @_disfavoredOverload
  public subscript<Value>(case keyPath: CaseKeyPath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let `case` = Case(keyPath)
      guard `case`._extract(from: self) != nil else { return }
      self = `case`._embed(newValue) as! Self
    }
  }

  /// Extracts the associated value of a case via dynamic member lookup.
  ///
  /// Simply annotate the base type with `@dynamicMemberLookup` to enable this functionality:
  ///
  /// ```swift
  /// @CasePathable
  /// @dynamicMemberLookup
  /// enum UserAction {
  ///   case home(HomeAction)
  ///   case settings(SettingsAction)
  /// }
  ///
  /// let userAction: UserAction = .home(.onAppear)
  /// userAction.home      // Optional(HomeAction.onAppear)
  /// userAction.settings  // nil
  ///
  /// let userActions: [UserAction] = [.home(.onAppear), .settings(.subscribeButtonTapped)]
  /// userActions.compactMap(\.home)      // [HomeAction.onAppear]
  /// userActions.compactMap(\.settings)  // [SettingsAction.subscribeButtonTapped]
  /// ```
  public subscript<Value>(
    dynamicMember keyPath: KeyPath<Self.AllCasePaths, AnyCasePath<Self, Value>>
  ) -> Value? {
    get { Self.allCasePaths[keyPath: keyPath].extract(from: self) }
    @available(*, unavailable, message: "Write 'enum = .case(value)', not 'enum.case = value'")
    set {
      let casePath = Self.allCasePaths[keyPath: keyPath]
      guard casePath.extract(from: self) != nil else {
        return
      }
      if let newValue {
        self = casePath.embed(newValue)
      }
    }
  }

  /// Embeds the associated value of a case via dynamic member lookup.
  @_disfavoredOverload
  public subscript<Value>(
    dynamicMember keyPath: KeyPath<Self.AllCasePaths, AnyCasePath<Self, Value>>
  ) -> Value {
    @available(*, unavailable)
    get { Self.allCasePaths[keyPath: keyPath].extract(from: self)! }
    set {
      let casePath = Self.allCasePaths[keyPath: keyPath]
      guard casePath.extract(from: self) != nil else {
        return
      }
      self = casePath.embed(newValue)
    }
  }

  /// Tests the associated value of a case.
  ///
  /// ```swift
  /// @CasePathable
  /// enum UserAction {
  ///   case home(HomeAction)
  ///   case settings(SettingsAction)
  /// }
  ///
  /// let userAction: UserAction = .home(.onAppear)
  /// userAction.is(\.home)      // true
  /// userAction.is(\.settings)  // false
  ///
  /// let userActions: [UserAction] = [.home(.onAppear), .settings(.subscribeButtonTapped)]
  /// userActions.filter { $0.is(\.home) }      // [UserAction.home(.onAppear)]
  /// userActions.filter { $0.is(\.settings) }  // [UserAction.settings(.subscribeButtonTapped)]
  /// ```
  public func `is`(_ keyPath: PartialCaseKeyPath<Self>) -> Bool {
    self[case: keyPath] != nil
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
  ///   - fileID: The fileID where the modify occurs.
  ///   - filePath: The filePath where the modify occurs.
  ///   - line: The line where the modify occurs.
  ///   - column: The column where the modify occurs.
  public mutating func modify<Value>(
    _ keyPath: CaseKeyPath<Self, Value>,
    yield: (inout Value) -> Void,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    let `case` = Case(keyPath)
    guard var value = `case`._extract(from: self) else {
      reportIssue(
        """
        Can't modify '\(String(describing: self))' via 'CaseKeyPath<\(Self.self), \(Value.self)>' \
        (aka '\(String(reflecting: keyPath))')
        """,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return
    }
    yield(&value)
    self = `case`._embed(value) as! Self
  }
}

extension AnyCasePath {
  /// Creates a type-erased case path for given case key path.
  ///
  /// - Parameter keyPath: A case key path.
  public init(_ keyPath: CaseKeyPath<Root, Value>) {
    let `case` = Case(keyPath)
    self.init(
      embed: { `case`._embed($0) as! Root },
      extract: { `case`._extract(from: $0) }
    )
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
    let keyPath = keyPath.unsafeSendable()
    return AnyCasePath<Root, AppendedValue>(
      embed: {
        embed(Value.allCasePaths[keyPath: keyPath].embed($0))
      },
      extract: {
        extract(from: $0).flatMap(
          Value.allCasePaths[keyPath: keyPath].extract(from:)
        )
      }
    )
  }
}
