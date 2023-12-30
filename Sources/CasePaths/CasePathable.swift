import XCTestDynamicOverlay

/// A type that provides a collection of all of its case paths.
///
/// Use the ``CasePathable()`` macro to automatically add case paths, and this conformance, to an
/// enum.
///
/// It is also possible, though less common, to manually conform a type to `CasePathable`. For
/// example, the `Result` type can be extended to be case-pathable with the following extension:
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

#if swift(>=5.9)
  /// A type that is used to distinguish case key paths from key paths by wrapping the enum and
  /// associated value types.
  @_documentation(visibility:internal)
  @dynamicMemberLookup
  public struct Case<Value> {
    @usableFromInline
    let path: any _PartialCasePath<Value>

    @inlinable
    init(path: any _PartialCasePath<Value>) {
      self.path = path
    }
  }
#else
  @dynamicMemberLookup
  public struct Case<Value> {
    @usableFromInline
    let path: any _PartialCasePath<Value>

    @inlinable
    init(path: any _PartialCasePath<Value>) {
      self.path = path
    }
  }
#endif

extension Case {
  @available(*, deprecated, message: "Use 'init(path:)' instead.")
  public init<Root>(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?
  ) {
    self.init(path: AnyCasePath(embed: embed, extract: extract))
  }

  @available(*, deprecated, message: "Use 'init(path:)' instead.")
  public init() {
    self.init(path: _IdentityCasePath())
  }

  @available(*, deprecated, message: "Use 'init(path:)' instead.")
  public init<Root>(_ keyPath: CaseKeyPath<Root, Value>) {
    self = Case<Root>(path: _IdentityCasePath())[keyPath: keyPath]
  }

  @inlinable
  public func appending<AppendedValue>(
    path: some CasePathProtocol<Value, AppendedValue>
  ) -> Case<AppendedValue> {
    Case<AppendedValue>(path: self.path.appending(path: path))
  }

  @inlinable
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, Member>
  ) -> Case<Member.Value>
  where Value: CasePathable, Member: CasePathProtocol, Member.Root == Value {
    self.appending(path: Value.allCasePaths[keyPath: keyPath])
  }

  @available(*, deprecated, message: "Use 'path.embed(_:)' instead.")
  public func embed(_ value: Value) -> Any {
    let path = self.path as! any CasePathProtocol
    func open<P: CasePathProtocol>(_ path: P) -> Any {
      return path.embed(value as! P.Value)
    }
    return open(path)
  }

  @available(*, deprecated, message: "Use 'path.extract(from:)' instead.")
  public func extract(from root: Any) -> Value? {
    let path = self.path as! any CasePathProtocol
    func open<P: CasePathProtocol>(_ path: P) -> Value? {
      guard let root = root as? P.Root else { return nil }
      return path.extract(from: root) as? Value
    }
    return open(path)
  }
}

private protocol _AnyCase {
  func _extract(from root: Any) -> Any?
}

extension Case: _AnyCase {
  fileprivate func _extract(from root: Any) -> Any? {
    let path = self.path as! any CasePathProtocol
    func open<P: CasePathProtocol>(_ path: P) -> Any? {
      guard let root = root as? P.Root else { return nil }
      return path.extract(from: root)
    }
    return open(path)
  }
}

/// A key path to the associated value of an enum case.
///
/// The most common way to make an instance of this type is by applying the ``CasePathable()`` macro
/// to an enum and using a key path expression like `\SomeEnum.Cases.someCase`, or simply
/// `\.someCase` where the type can be inferred.
///
/// To extract an associated value from an enum using a case key path, pass the key path to the
/// ``CasePathable/subscript(case:)-6cdhl``. For example:
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
/// To replace an associated value, assign it through ``CasePathable/subscript(case:)-8yr2s``. If
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
  @inlinable
  public func asCasePath<Enum, AssociatedValue>() -> any CasePathProtocol<Enum, AssociatedValue>
  where Root == Case<Enum>, Value == Case<AssociatedValue> {
    let path = Case<Enum>(path: _IdentityCasePath())[keyPath: self].path
    if #available(iOS 16, macOS 13, tvOS 16, watchOS 10, *) {
      return path as! any CasePathProtocol<Enum, AssociatedValue>
    } else {
      let path = path as! any CasePathProtocol
      func open<P: CasePathProtocol>(_ path: P) -> AnyCasePath<Enum, AssociatedValue> {
        AnyCasePath<P.Root, P.Value>(path) as! AnyCasePath<Enum, AssociatedValue>
      }
      return open(path)
    }
  }

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
  @inlinable
  public func callAsFunction<Enum, AssociatedValue>(_ value: AssociatedValue) -> Enum
  where Root == Case<Enum>, Value == Case<AssociatedValue> {
    self.asCasePath().embed(value)
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
  @inlinable
  public func callAsFunction<Enum>() -> Enum
  where Root == Case<Enum>, Value == Case<Void> {
    self.asCasePath().embed(())
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
  @inlinable
  public static func ~= <Enum: CasePathable, AssociatedValue>(lhs: KeyPath, rhs: Enum) -> Bool
  where Root == Case<Enum>, Value == Case<AssociatedValue> {
    rhs[case: lhs] != nil
  }
}

/// A partially type-erased key path, from a concrete root enum to any resulting value type.
public typealias PartialCaseKeyPath<Root> = PartialKeyPath<Case<Root>>

extension PartialCaseKeyPath {
  /// Attempts to embeds any value in an enum at this case key path's case.
  ///
  /// - Parameter value: A value to embed. If the value type does not match the case path's value
  ///   type, the operation will fail.
  /// - Returns: An enum for the case of this key path that holds the given value, or `nil`.
  @_disfavoredOverload
  public func callAsFunction<Enum: CasePathable, AnyAssociatedValue>(
    _ value: AnyAssociatedValue
  ) -> Enum?
  where Root == Case<Enum> {
    (self as? CaseKeyPath<Enum, AnyAssociatedValue>)?(value)
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
  /// See ``CasePathable/subscript(case:)-8yr2s`` for replacing an associated value in a root
  /// enum, and see ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a
  /// brand new root enum.
  @inlinable
  public subscript<Value>(case keyPath: CaseKeyPath<Self, Value>) -> Value? {
    keyPath.asCasePath().extract(from: self)
  }

  /// Attempts to extract the associated value from a root enum using a partial case key path.
  @_disfavoredOverload
  public subscript(case keyPath: PartialCaseKeyPath<Self>) -> Any? {
    (Case<Self>(path: _IdentityCasePath())[keyPath: keyPath] as? any _AnyCase)?._extract(from: self)
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
  /// See ``CasePathable/subscript(case:)-6cdhl`` for extracting an associated value from a root
  /// enum, and see ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a
  /// brand new root enum.
  @_disfavoredOverload
  public subscript<Value>(case keyPath: CaseKeyPath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    @inlinable
    set {
      let casePath = keyPath.asCasePath()
      guard casePath.extract(from: self) != nil else { return }
      self = casePath.embed(newValue)
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
  @inlinable
  public subscript<Member: CasePathProtocol>(
    dynamicMember keyPath: KeyPath<Self.AllCasePaths, Member>
  ) -> Member.Value?
  where Member.Root == Self {
    Self.allCasePaths[keyPath: keyPath].extract(from: self)
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
  @inlinable
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
  public mutating func modify<Value>(
    _ keyPath: CaseKeyPath<Self, Value>,
    yield: (inout Value) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let casePath = keyPath.asCasePath()
    guard var value = casePath.extract(from: self) else {
      XCTFail(
        """
        Can't modify '\(String(describing: self))' via 'CaseKeyPath<\(Self.self), \(Value.self)>' \
        (aka '\(String(reflecting: keyPath))')
        """,
        file: file,
        line: line
      )
      return
    }
    yield(&value)
    self = casePath.embed(value)
  }
}

extension AnyCasePath {
  /// Creates a type-erased case path for given case key path.
  ///
  /// - Parameter keyPath: A case key path.
  @inlinable
  public init(_ keyPath: CaseKeyPath<Root, Value>) {
    self.init(keyPath.asCasePath())
  }
}

extension AnyCasePath where Value: CasePathable {
  /// Returns a new case path created by appending the case path at the given key path to this one.
  ///
  /// This subscript is automatically invoked by case key path expressions via dynamic member
  /// lookup, and should not be invoked directly.
  ///
  /// - Parameter keyPath: A key path to a case-pathable case path.
  @available(*, deprecated, message: "Append case key paths, instead.")
  public subscript<Member: CasePathProtocol>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, Member>
  ) -> AnyCasePath<Root, Member.Value>
  where Member.Root == Value {
    func open<P: CasePathProtocol<Root, Value>>(
      _ path: P
    ) -> AnyCasePath<Root, Member.Value> {
      AnyCasePath<Root, Member.Value>(path.appending(path: Value.allCasePaths[keyPath: keyPath]))
    }
    return open(self.base)
  }
}
