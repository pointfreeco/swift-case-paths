public typealias CasePath<Root: CasePathable, Value> = KeyPath<
  AnyCasePath<Root, Root>, AnyCasePath<Root, Value>
>

extension CasePath {
  public func callAsFunction<Enum: CasePathable, AssociatedValue>(_ value: AssociatedValue) -> Enum
  where Root == AnyCasePath<Enum, Enum>, Value == AnyCasePath<Enum, AssociatedValue> {
    AnyCasePath(self).embed(value)
  }

  public func callAsFunction<Enum: CasePathable>() -> Enum
  where Root == AnyCasePath<Enum, Enum>, Value == AnyCasePath<Enum, Void> {
    AnyCasePath(self).embed(())
  }
}
