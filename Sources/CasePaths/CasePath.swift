public typealias CasePath<Root: CasePathable, Value> = KeyPath<Case<Root, Root>, Case<Root, Value>>

@dynamicMemberLookup
public struct Case<Root: CasePathable, Value> {
  let embed: (Value) -> Root
  let extract: (Root) -> Value?

  public init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?
  ) {
    self.embed = embed
    self.extract = extract
  }

  public subscript<AppendedValue>(
    dynamicMember keyPath: KeyPath<Value.Cases, Case<Value, AppendedValue>>
  ) -> Case<Root, AppendedValue> {
    Case<Root, AppendedValue>(
      embed: { self.embed(Value.cases[keyPath: keyPath].embed($0)) },
      extract: { self.extract($0).flatMap(Value.cases[keyPath: keyPath].extract) }
    )
  }
}

extension Case where Root == Value {
  public init() {
    self.init(embed: { $0 }, extract: { $0 })
  }
}
