extension CasePath where Root: CasePathable {
  public init(embed: @escaping (Value) -> Root, extract: KeyPath<Root, Value?>) {
    self.init(embed: embed, extract: { $0[keyPath: extract] })
  }
}

public protocol CasePathable {
  static var cases: Cases<Self> { get }
}

public struct Cases<Root: CasePathable> {
  fileprivate let elements: [PartialKeyPath<Root>: Any]

  public init(_ cases: some Collection<Case<Root>>) {
    self.elements = Dictionary(uniqueKeysWithValues: cases.map { ($0.extract, $0.embed) })
  }
}

public struct Case<Root: CasePathable> {
  fileprivate let embed: Any
  fileprivate let extract: PartialKeyPath<Root>

  public init<Value>(embed: @escaping (Value) -> Root, extract: KeyPath<Root, Value?>) {
    self.embed = embed
    self.extract = extract
  }

  public init(embed: @autoclosure @escaping () -> Root, extract: KeyPath<Root, Void?>) {
    self.embed = embed
    self.extract = extract
  }
}

extension Optional: CasePathable {
  public var some: Wrapped? { if case let .some(value) = self { value } else { nil } }
  public var none: Void? { if case .none = self { () } else { nil } }

  public static var cases: Cases<Self> {
    Cases([
      Case(embed: some, extract: \.some),
      Case(embed: none, extract: \.none),
    ])
  }
}

extension Result: CasePathable {
  public var success: Success? { if case let .success(value) = self { value } else { nil } }
  public var failure: Failure? { if case let .failure(value) = self { value } else { nil } }

  public static var cases: Cases<Self> {
    Cases([
      Case(embed: success, extract: \.success),
      Case(embed: failure, extract: \.failure),
    ])
  }
}
