public protocol CasePathSubscriptable {}

/// Opt in protocol to allow subscripting of case paths in a similar way to key paths on structs
public extension CasePathSubscriptable {
  /// Attempts to extract a value from an enum
  ///
  /// - Parameter casePath: a case path for this enum
  /// - Returns: A value iff it can be extracted from the given root, otherwise `nil`.
  subscript <T>(casePath casePath: CasePath<Self, T>) -> T? {
    get {
      return casePath.extract(from: self)
    }
  }
}
