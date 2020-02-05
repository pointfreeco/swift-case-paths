public protocol CasePathSubscriptable {}

/// Opt in protocol to allow subscripting of case paths in a similar way to key paths on structs
public extension CasePathSubscriptable {
  subscript <T>(casePath casePath: CasePath<Self, T>) -> T? {
    get {
      return casePath.extract(from: self)
    }
  }
}
