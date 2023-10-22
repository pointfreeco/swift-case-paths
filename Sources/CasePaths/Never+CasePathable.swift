extension Never: CasePathable, CasePathIterable {
  public struct AllCasePaths: RandomAccessCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { 0 }
    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
    public subscript(position: Int) -> PartialCaseKeyPath<Never> {
      fatalError("Index out of range")
    }
  }
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}
