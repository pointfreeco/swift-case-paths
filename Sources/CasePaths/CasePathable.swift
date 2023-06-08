extension CasePath where Root: CasePathable {
  public init(embed: @escaping (Value) -> Root, extract: KeyPath<Root, Value?>) {
    self.init(embed: embed, extract: { $0[keyPath: extract] })
  }
}

public protocol CasePathable {}

extension Optional: CasePathable {
  public var some: Wrapped? { if case let .some(value) = self { value } else { nil } }
  public var none: Void? { if case .none = self { () } else { nil } }
}

extension Result: CasePathable {
  public var success: Success? { if case let .success(value) = self { value } else { nil } }
  public var failure: Failure? { if case let .failure(value) = self { value } else { nil } }
}
