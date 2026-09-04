extension Never: CasePathable {
  public struct AllCasePaths: CasePath, Hashable, Sendable {
    public func embed(_ value: Never) -> Never {}
    public func extract(from root: Never) -> Never? {}
  }

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public var `case`: PartialCaseKeyPath<Never> {
    \.never
  }

  public static var _allCaseKeyPaths: [PartialCaseKeyPath<Never>] {
    []
  }
}

public struct _NeverCasePath<Root>: CasePath, Hashable, Sendable {
  public func embed(_ value: Never) -> Root {}
  public func extract(from root: Root) -> Never? { nil }
}

extension CasePath where Value: CasePathable {
  /// A case path that can never embed or extract a value.
  ///
  /// This property can chain any case path into a `Never` value, which, as an uninhabited type,
  /// cannot be embedded nor extracted from an enum.
  public var never: _AppendCasePath<Self, _NeverCasePath<Value>> {
    _AppendCasePath(_base: self, _appended: _NeverCasePath())
  }
}

extension Never.AllCasePaths: Sequence {
  public func makeIterator() -> some IteratorProtocol<PartialCaseKeyPath<Never>> {
    [].makeIterator()
  }
}
