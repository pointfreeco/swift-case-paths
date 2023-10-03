public protocol CasePathable {
  associatedtype AllCasePaths
  static var allCasePaths: AllCasePaths { get }
}

public typealias CaseKeyPath<Root: CasePathable, Value> = KeyPath<
  AnyCasePath<Root, Root>, AnyCasePath<Root, Value>
>

extension CaseKeyPath {
  public func callAsFunction<Enum: CasePathable, AssociatedValue>(_ value: AssociatedValue) -> Enum
  where Root == AnyCasePath<Enum, Enum>, Value == AnyCasePath<Enum, AssociatedValue> {
    AnyCasePath(self).embed(value)
  }

  public func callAsFunction<Enum: CasePathable>() -> Enum
  where Root == AnyCasePath<Enum, Enum>, Value == AnyCasePath<Enum, Void> {
    AnyCasePath(self).embed(())
  }
}

extension CasePathable {
  public typealias Cases = AnyCasePath<Self, Self>

  public subscript<Value>(keyPath keyPath: CaseKeyPath<Self, Value>) -> Value? {
    AnyCasePath(keyPath).extract(from: self)
  }

  @_disfavoredOverload
  public subscript<Value>(keyPath keyPath: CaseKeyPath<Self, Value>) -> Value {
    @available(*, unavailable)
    get { fatalError() }
    set {
      let `case` = AnyCasePath(keyPath)
      guard `case`.extract(from: self) != nil else { return }
      self = `case`.embed(newValue)
    }
  }
}

extension AnyCasePath where Root: CasePathable {
  public init(_ keyPath: CaseKeyPath<Root, Value>) {
    self = AnyCasePath<Root, Root>()[keyPath: keyPath]
  }
}

extension AnyCasePath where Value: CasePathable {
  public subscript<AppendedValue>(
    dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, AppendedValue>>
  ) -> AnyCasePath<Root, AppendedValue> {
    AnyCasePath<Root, AppendedValue>(
      embed: { self.embed(Value.allCasePaths[keyPath: keyPath].embed($0)) },
      extract: {
        self.extract(from: $0).flatMap(Value.allCasePaths[keyPath: keyPath].extract(from:))
      }
    )
  }
}
