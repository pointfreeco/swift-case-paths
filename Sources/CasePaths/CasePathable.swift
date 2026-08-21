import IssueReporting

/// A type that provides a collection of all of its case paths.
///
/// Use the `@CasePathable` macro to automatically add case paths, and this conformance, to an
/// enum.
///
/// It is also possible, though less common, to manually conform a type to `CasePathable`. For
/// example, the `Result` type is extended to be case-pathable with the following extension:
///
/// ```swift
/// extension Result: CasePathable {
///   public struct AllCasePaths: CasePath {
///     public func embed(_ value: Result) -> Result { value }
///     public func extract(from root: Result) -> Result? { root }
///
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
  ///
  /// This type conforms to ``CasePath`` as the identity case path of the enum, which gives the
  /// identity case key path `\SomeEnum.Cases.self` the same currency as any other case key path.
  /// It can also reflect the case of a given value (via ``CasePathReflectable``), and is a
  /// `Sequence` of all of the enum's case key paths:
  ///
  /// ```swift
  /// @CasePathable enum Field {
  ///   case title(String)
  ///   case body(String)
  ///   case isLive
  /// }
  ///
  /// Array(Field.allCasePaths)  // [\.title, \.body, \.isLive]
  /// ```
  associatedtype AllCasePaths: CasePathReflectable<Self>

  /// A collection of all case paths of this type.
  static var allCasePaths: AllCasePaths { get }

  /// Returns the case name for a given case key path, if available.
  ///
  /// - Parameter keyPath: A partial case key path.
  /// - Returns: The name of the case, or `nil` if the key path doesn't match a known case.
  static func caseName(for keyPath: PartialCaseKeyPath<Self>) -> String?
}

extension CasePathable {
  public static func caseName(for keyPath: PartialCaseKeyPath<Self>) -> String? { nil }
}

/// A key path to the associated value of an enum case.
///
/// The most common way to make an instance of this type is by applying the `@CasePathable` macro
/// to an enum and using a key path expression like `\SomeEnum.Cases.someCase`, or simply
/// `\.someCase` where the type can be inferred.
///
/// Case key paths are ordinary key paths into the enum's ``CasePathable/AllCasePaths`` namespace,
/// and their values conform to the ``CasePath`` protocol. A library function that takes a case
/// key path can recover the underlying case path—and its statically-known conformance—by applying
/// the key path a single time:
///
/// ```swift
/// func scoped<Enum, Path>(to keyPath: CaseKeyPath<Enum, Path>) {
///   let path = Enum.allCasePaths[keyPath: keyPath]
///   // Use 'path.extract(from:)' and 'path.embed(_:)' freely.
/// }
/// ```
///
/// To extract an associated value from an enum using a case key path, pass the key path to the
/// ``CasePathable/subscript(case:)``. For example:
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
/// To replace an associated value, assign it through ``CasePathable/subscript(case:)``. If
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
/// To produce a whole instance from a case key path, call the key path directly with the
/// associated value you'd like to embed (via ``Swift/KeyPath/callAsFunction(_:)``):
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
/// identity case key path `\SomeEnum.Cases.self`. It refers to the whole enum and can be passed
/// to a function that takes case key paths when you want to extract, change, or replace all of
/// the data stored in an enum in a single step.
public typealias CaseKeyPath<Root: CasePathable, Path: CasePath> =
  KeyPath<Root.AllCasePaths, Path> where Path.Root == Root

/// A partially type-erased key path, from a concrete root enum to any resulting value type.
public typealias PartialCaseKeyPath<Root: CasePathable> = PartialKeyPath<Root.AllCasePaths>

extension KeyPath {
  /// Embeds a value in an enum at this case key path's case.
  ///
  /// Given a case key path to an enum case, one can produce a whole new root value to that case
  /// by invoking the key path like a function with an associated value to embed. For example:
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
  public func callAsFunction<Enum: CasePathable>(_ value: Value.Value) -> Enum
  where Root == Enum.AllCasePaths, Value: CasePath, Value.Root == Enum {
    Enum.allCasePaths[keyPath: self].embed(value)
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
  public func callAsFunction<Enum: CasePathable>() -> Enum
  where Root == Enum.AllCasePaths, Value: CasePath, Value.Root == Enum, Value.Value == Void {
    Enum.allCasePaths[keyPath: self].embed(())
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
  public static func ~= <Enum: CasePathable>(lhs: KeyPath, rhs: Enum) -> Bool
  where Root == Enum.AllCasePaths, Value: CasePath, Value.Root == Enum {
    Enum.allCasePaths[keyPath: lhs].extract(from: rhs) != nil
  }
}

extension PartialKeyPath {
  /// Attempts to embeds any value in an enum at this case key path's case.
  ///
  /// - Parameter value: A value to embed. If the value type does not match the case path's value
  ///   type, the operation will fail.
  /// - Returns: An enum for the case of this key path that holds the given value, or `nil`.
  @_disfavoredOverload
  public func callAsFunction(
    _ value: Any
  ) -> Root.Root?
  where Root: CasePath, Root.Root: CasePathable, Root == Root.Root.AllCasePaths {
    guard let path = Root.Root.allCasePaths[keyPath: self] as? any CasePath
    else { return nil }
    func open<P: CasePath>(_ path: P) -> Root.Root? {
      guard let value = value as? P.Value
      else { return nil }
      return path.embed(value) as? Root.Root
    }
    return open(path)
  }
}

extension CasePathable {
  /// A namespace that can be used to derive case key paths from case-pathable enums.
  ///
  /// One can fully-qualify a ``CaseKeyPath`` for a type conforming to ``CasePathable`` through
  /// this namespace. For example:
  ///
  /// ```swift
  /// @CasePathable
  /// enum SomeEnum {
  ///   case someCase(Int)
  /// }
  ///
  /// \SomeEnum.Cases.someCase  // CaseKeyPath<SomeEnum, SomeEnum.AllCasePaths._someCase>
  /// ```
  public typealias Cases = AllCasePaths

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
  /// See ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a brand new
  /// root enum.
  @inlinable
  public subscript<Path>(case keyPath: CaseKeyPath<Self, Path>) -> Path.Value? {
    Self.allCasePaths[keyPath: keyPath].extract(from: self)
  }

  /// Attempts to extract the associated value from a root enum using a partial case key path.
  @_disfavoredOverload
  public subscript(case keyPath: PartialCaseKeyPath<Self>) -> Any? {
    guard let path = Self.allCasePaths[keyPath: keyPath] as? any CasePath
    else { return nil }
    func open<P: CasePath>(_ path: P) -> Any? {
      guard let root = self as? P.Root
      else { return nil }
      return path.extract(from: root).map { $0 as Any }
    }
    return open(path)
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
  /// See ``Swift/KeyPath/callAsFunction(_:)`` for embedding an associated value in a brand new
  /// root enum.
  @_disfavoredOverload
  public subscript<Path>(case keyPath: CaseKeyPath<Self, Path>) -> Path.Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let path = Self.allCasePaths[keyPath: keyPath]
      guard path.extract(from: self) != nil else { return }
      self = path.embed(newValue)
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
  public subscript<Path>(
    dynamicMember keyPath: CaseKeyPath<Self, Path>
  ) -> Path.Value? {
    @inlinable
    get { Self.allCasePaths[keyPath: keyPath].extract(from: self) }
    @available(*, unavailable, message: "Write 'enum = .case(value)', not 'enum.case = value'")
    set {
      let path = Self.allCasePaths[keyPath: keyPath]
      guard path.extract(from: self) != nil else {
        return
      }
      if let newValue {
        self = path.embed(newValue)
      }
    }
  }

  /// Embeds the associated value of a case via dynamic member lookup.
  @_disfavoredOverload
  public subscript<Path>(
    dynamicMember keyPath: CaseKeyPath<Self, Path>
  ) -> Path.Value {
    @available(*, unavailable)
    get { Self.allCasePaths[keyPath: keyPath].extract(from: self)! }
    set {
      let path = Self.allCasePaths[keyPath: keyPath]
      guard path.extract(from: self) != nil else {
        return
      }
      self = path.embed(newValue)
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
  /// > Warning: If the enum's case does not match the given case key path, the mutation will not
  /// > be applied, and a runtime warning will be logged. To suppress these warnings, limit calls
  /// > to `modify` to instances in which you have already checked the enum case. For example:
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
  public mutating func modify<Path>(
    _ keyPath: CaseKeyPath<Self, Path>,
    yield: (inout Path.Value) -> Void,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    let path = Self.allCasePaths[keyPath: keyPath]
    guard var value = path.extract(from: self) else {
      reportIssue(
        """
        Can't modify '\(String(describing: self))' via \
        'CaseKeyPath<\(Self.self), \(Path.Value.self)>' \
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
    self = path.embed(value)
  }
}

extension CasePathable {
  /// A case key path to this enum's case.
  public var `case`: PartialCaseKeyPath<Self> {
    Self.allCasePaths[self]
  }
}

extension AnyCasePath where Root: CasePathable {
  /// Creates a type-erased case path for a given case key path.
  ///
  /// - Parameter keyPath: A case key path.
  public init(_ keyPath: CaseKeyPath<Root, some CasePath<Root, Value>>) {
    self.init(Root.allCasePaths[keyPath: keyPath])
  }
}
