extension Optional: CasePathable {
  @inlinable
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    @inlinable
    public var none: some CasePathProtocol<Optional, Void> { _None() }
    @inlinable
    public var some: some CasePathProtocol<Optional, Wrapped> { _Some() }
    @inlinable
    public init() {}

    public struct _None: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Void) -> Optional { .none }
      @inlinable
      public func extract(from root: Optional) -> Void? { root == nil ? () : nil }
    }
    public struct _Some: CasePathProtocol {
      @inlinable
      public init() {}
      @inlinable
      public func embed(_ value: Wrapped) -> Optional { value }
      @inlinable
      public func extract(from root: Optional) -> Wrapped? { root }
    }
  }
}
