public protocol CasePathable {
  associatedtype Cases
  static var cases: Cases { get }
}

extension CasePathable {
  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value? {
    Self.cases[keyPath: keyPath].extract(self)
  }

  @_disfavoredOverload
  public subscript<Value>(keyPath keyPath: CasePath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let casePath = Self.cases[keyPath: keyPath]
      guard casePath.extract(self) != nil else { return }
      self = casePath.embed(newValue)
    }
  }
}

extension KeyPath {
  public func callAsFunction<Enum: CasePathable, AssociatedValue>(
    _ value: AssociatedValue
  ) -> Enum
  where Root == Enum.Cases, Value == Case<Enum, AssociatedValue> {
    Enum.cases[keyPath: self].embed(value)
  }

  public func callAsFunction<Enum: CasePathable>() -> Enum
  where Root == Enum.Cases, Value == Case<Enum, Void> {
    Enum.cases[keyPath: self].embed(())
  }
}
