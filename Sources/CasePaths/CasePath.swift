public typealias CasePath<Root: CasePathable, Value> = KeyPath<Root.Cases, Case<Root, Value>>

@dynamicMemberLookup
public struct Case<Root, Value> {
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
    dynamicMember keyPath: CasePath<Value, AppendedValue>
  ) -> Case<Root, AppendedValue> {
    Case<Root, AppendedValue>(
      embed: { self.embed(Value.cases[keyPath: keyPath].embed($0)) },
      extract: { self.extract($0).flatMap(Value.cases[keyPath: keyPath].extract) }
    )
  }
}
