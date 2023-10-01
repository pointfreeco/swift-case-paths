@dynamicMemberLookup
public struct AnyCasePath<Root, Value> {
  let _embed: (Value) -> Root
  let _extract: (Root) -> Value?

  public init(
    embed: @escaping (Value) -> Root,
    extract: @escaping (Root) -> Value?
  ) {
    self._embed = embed
    self._extract = extract
  }

  public func embed(_ value: Value) -> Root {
    self._embed(value)
  }

  public func extract(from root: Root) -> Value? {
    self._extract(root)
  }
}

extension AnyCasePath where Root == Value {
  public init() {
    self.init(embed: { $0 }, extract: { $0 })
  }
}

extension AnyCasePath where Root: CasePathable {
  init(_ keyPath: CasePath<Root, Value>) {
    self = AnyCasePath<Root, Root>()[keyPath: keyPath]
  }
}

extension AnyCasePath where Root: CasePathable, Value: CasePathable {
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
