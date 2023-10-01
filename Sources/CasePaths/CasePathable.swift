public protocol CasePathable {
  associatedtype AllCasePaths
  static var allCasePaths: AllCasePaths { get }
}

extension CasePathable {
  public typealias Cases = Case<Self, Self>

  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value? {
    Case()[keyPath: keyPath].extract(self)
  }

  @_disfavoredOverload
  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let `case` = Case()[keyPath: keyPath]
      guard `case`.extract(self) != nil else { return }
      self = `case`.embed(newValue)
    }
  }
}

extension KeyPath {
  public func callAsFunction<Enum: CasePathable, AssociatedValue>(
    _ value: AssociatedValue
  ) -> Enum
  where Root == Case<Enum, Enum>, Value == Case<Enum, AssociatedValue> {
    Case()[keyPath: self].embed(value)
  }

  public func callAsFunction<Enum: CasePathable>() -> Enum
  where Root == Case<Enum, Enum>, Value == Case<Enum, Void> {
    Case()[keyPath: self].embed(())
  }
}
