public protocol CasePathable {
  associatedtype Cases
  static var cases: Cases { get }
}

extension CasePathable {
  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value? {
    Case<Self, Self>()[keyPath: keyPath].extract(self)
  }

  @_disfavoredOverload
  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let `case` = Case<Self, Self>()[keyPath: keyPath]
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
