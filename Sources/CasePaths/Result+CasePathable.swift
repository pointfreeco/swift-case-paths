extension Result: CasePathable {
  public struct AllCasePaths: CasePath, Hashable, Sendable {
    public func embed(_ value: Result) -> Result { value }

    public func extract(from root: Result) -> Result? { root }

    @frozen
    public struct _$success: CasePath, Hashable, Sendable {
      @inlinable
      public init() {}

      @inlinable
      public func embed(_ value: Success) -> Result { .success(value) }

      @inlinable
      public func extract(from root: Result) -> Success? {
        guard case .success(let value) = root else { return nil }
        return value
      }
    }

    /// A success case path, for embedding or extracting a `Success` value.
    public var success: _$success { _$success() }

    @frozen
    public struct _$failure: CasePath, Hashable, Sendable {
      @inlinable
      public init() {}

      @inlinable
      public func embed(_ value: Failure) -> Result { .failure(value) }

      @inlinable
      public func extract(from root: Result) -> Failure? {
        guard case .failure(let value) = root else { return nil }
        return value
      }
    }

    /// A failure case path, for embedding or extracting a `Failure` value.
    public var failure: _$failure { _$failure() }
  }

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public var `case`: PartialCaseKeyPath<Result> {
    switch self {
    case .success: return \.success
    case .failure: return \.failure
    }
  }

  public static var _allCaseKeyPaths: [PartialCaseKeyPath<Result>] {
    [\.success, \.failure]
  }

  public static func caseName(for keyPath: PartialCaseKeyPath<Self>) -> String? {
    switch keyPath {
    case \.success: return "success"
    case \.failure: return "failure"
    default: return nil
    }
  }
}

extension Result.AllCasePaths: Sequence {
  public func makeIterator() -> some IteratorProtocol<PartialCaseKeyPath<Result>> {
    [\.success, \.failure].makeIterator()
  }
}
