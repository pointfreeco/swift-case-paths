public protocol CasePathable {
  associatedtype AllCasePaths
  static var allCasePaths: AllCasePaths { get }
}

extension CasePathable {
  public typealias Cases = AnyCasePath<Self, Self>

  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value? {
    AnyCasePath(keyPath).extract(from: self)
  }

  @_disfavoredOverload
  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let `case` = AnyCasePath(keyPath)
      guard `case`.extract(from: self) != nil else { return }
      self = `case`.embed(newValue)
    }
  }
}
