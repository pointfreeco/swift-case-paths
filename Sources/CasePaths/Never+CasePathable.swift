extension Never: CasePathable {
  public struct AllCasePaths {}
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}

extension Case {
  public var never: Case<Never> {
    Case<Never>(path: self.path.appending(path: _Never<Value>()))
  }
}

private struct _Never<Root>: CasePathProtocol {
  func embed(_ value: Never) -> Root {}
  func extract(from root: Root) -> Never? { nil }
}
