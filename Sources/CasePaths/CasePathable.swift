import XCTestDynamicOverlay

/// A type that provides a collection of all of its case paths.
///
/// Use the ``CasePathable()`` macro to automatically add case paths to an enum.
///
/// It is also possible, though less common, to manually conform a type to ``CasePathable``. For
/// example, the `Result` type can be extended to be case-pathable with the following extension:
///
/// ```swift
/// extension Result: CasePathable {
///   public struct AllCasePaths {
///     var success: CasePath<Result, Success> {
///       ._$init(
///         embed: Result.success,
///         extract: {
///           guard case let .success(value) = $0 else { return nil }
///           return value
///         },
///         keyPath: \.success
///       )
///     }
///     var failure: CasePath<Result, Failure> {
///       ._$init(
///         embed: Result.failure,
///         extract: {
///           guard case let .failure(value) = $0 else { return nil }
///           return value
///         },
///         keyPath: \.failure
///       )
///     }
///   }
///   public static var allCasePaths: AllCasePaths { AllCasePaths() }
///   public var success: Success? { Self.allCasePaths.success.extract(from: self) }
///   public var failure: Failure? { Self.allCasePaths.failure.extract(from: self) }
/// }
/// ```
public protocol CasePathable {
  /// A type that can represent a collection of all case paths of this type.
  associatedtype AllCasePaths

  /// A collection of all case paths of this type.
  static var allCasePaths: AllCasePaths { get }
}

extension CasePath where Root: CasePathable {
  // NB: Invoked by `#casePath`
  public static func _$case(_ keyPath: KeyPath<Root.AllCasePaths, Self>) -> Self {
    Root.allCasePaths[keyPath: keyPath]
  }
}

extension CasePath where Root: CasePathable, Root == Value {
  // NB: Invoked by `#casePath`
  public static func _$case(_ keyPath: KeyPath<Root.AllCasePaths, Root.AllCasePaths>) -> Self {
    CasePath(
      embed: { $0 },
      extract: { $0 },
      keyPaths: []
    )
  }
}

extension CasePath where Root: CasePathable, Value: CasePathable {
  public func appending<AppendedValue>(
    path: CasePath<Value, AppendedValue>
  ) -> CasePath<Root, AppendedValue> {
    CasePath<Root, AppendedValue>(
      embed: { self.embed(path.embed($0)) },
      extract: { self.extract(from: $0).flatMap(path.extract) },
      keyPaths: self.keyPaths.flatMap { keyPaths in path.keyPaths.map { keyPaths + $0 } }
    )
  }
}

extension CasePath: Equatable where Root: CasePathable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard let lhsKeyPaths = lhs.keyPaths else {
      XCTFail(
        """
        Can't equate dynamic case path \(lhs.debugDescription). Use '#casePath' instead of \
        '/Enum.case' to preserve equatability.
        """
      )
      return false
    }
    guard let rhsKeyPaths = rhs.keyPaths else {
      XCTFail(
        """
        Can't equate dynamic case path \(rhs.debugDescription). Use '#casePath' instead of \
        '/Enum.case' to preserve equatability.
        """
      )
      return false
    }
    return lhsKeyPaths == rhsKeyPaths
  }
}

extension CasePath: Hashable where Root: CasePathable {
  public func hash(into hasher: inout Hasher) {
    guard let keyPaths = self.keyPaths else {
      XCTFail(
        """
        Can't hash dynamic case path \(self.debugDescription). Use '#casePath' instead of \
        '/Enum.case' to preserve hashability.
        """
      )
      return
    }
    hasher.combine(keyPaths)
  }
}

#if swift(>=5.9)
  extension CasePath {
    @available(
      *,
      deprecated,
      message:
        """
        Appending a dynamic case path to a '#casePath' loses equatability and hashability.
        """
    )
    public func appending<AppendedValue>(
      path: CasePath<Value, AppendedValue>
    ) -> CasePath<Root, AppendedValue> where Root: CasePathable {
      CasePath<Root, AppendedValue>(
        embed: { self.embed(path.embed($0)) },
        extract: { self.extract(from: $0).flatMap(path.extract) },
        keyPaths: self.keyPaths.flatMap { keyPaths in path.keyPaths.map { keyPaths + $0 } }
      )
    }

    @available(
      *,
      deprecated,
      message:
        """
        Appending a '#casePath' to a dynamic case path loses equatability and hashability.
        """
    )
    public func appending<AppendedValue>(
      path: CasePath<Value, AppendedValue>
    ) -> CasePath<Root, AppendedValue> where Value: CasePathable {
      CasePath<Root, AppendedValue>(
        embed: { self.embed(path.embed($0)) },
        extract: { self.extract(from: $0).flatMap(path.extract) },
        keyPaths: self.keyPaths.flatMap { keyPaths in path.keyPaths.map { keyPaths + $0 } }
      )
    }
  }
#endif
