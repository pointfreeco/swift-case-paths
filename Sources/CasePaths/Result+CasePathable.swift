extension Result: CasePathable {
  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var success: some CasePathProtocol<Result, Success> { _Success() }
    @inlinable
    public var failure: some CasePathProtocol<Result, Failure> { _Failure() }
    @inlinable
    public init() {}

    public struct _Success: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Success) -> Result { .success(value) }
      @inlinable
      public func extract(from root: Result) -> Success? {
        guard case let .success(value) = root else { return nil }
        return value
      }
    }
    public struct _Failure: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Failure) -> Result { .failure(value) }
      @inlinable
      public func extract(from root: Result) -> Failure? {
        guard case let .failure(value) = root else { return nil }
        return value
      }
    }
  }
}
