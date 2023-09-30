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


public typealias _CasePath<Root: CasePathable, Value> = KeyPath<Cases<Root>, Cases<Value>>

@dynamicMemberLookup
public struct Cases<Root> {}

extension Cases where Root: CasePathable {
  public subscript<Value>(dynamicMember keyPath: CasePath<Root, Value>) -> Cases<Value> {
    Cases<Value>()
  }
}

@CasePathable enum Food { case chicken(Int) }

func f<R, V>(_ cp: _CasePath<R, V>) -> _CasePath<R, V> {
  cp
}

func g() {
  let _: _CasePath<Food, Int> = f(\.chicken)
  let _: _CasePath<Food, Food> = f(\.self)
}
