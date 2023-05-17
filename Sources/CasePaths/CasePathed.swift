public protocol CasePathed {
  subscript<Value>(casePath casePath: CasePath<Self, Value>) -> Value? { get set }
}

extension CasePathed {
  public subscript<Value>(casePath casePath: CasePath<Self, Value>) -> Value? {
    get {
      return casePath.extract(from: self)
    }
    set {
      guard let newValue else { return }
      self = casePath.embed(newValue)
    }
  }
}
