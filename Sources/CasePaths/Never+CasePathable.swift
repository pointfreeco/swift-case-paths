extension Never: CasePathable {
  public struct AllCasePaths {}
  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }
}

extension Case {
  public var never: Case<Never> {
    func absurd<T>(_: Never) -> T {}
    return Case<Never>(embed: absurd, extract: { (_: Value) in nil })
  }
}
