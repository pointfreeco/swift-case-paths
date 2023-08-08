@attached(extension, conformances: CasePathable)
@attached(member, names: arbitrary)
public macro CasePathable() = #externalMacro(module: "CasePathsMacros", type: "CasePathableMacro")

@freestanding(expression)
public macro casePath<Root: CasePathable>(
  _ keyPath: KeyPath<Root, Root>
) -> CasePath<Root, Root> = #externalMacro(module: "CasePathsMacros", type: "CasePathMacro")

@freestanding(expression)
public macro casePath<Root: CasePathable, Value>(
  _ keyPath: KeyPath<Root, Value?>
) -> CasePath<Root, Value> = #externalMacro(module: "CasePathsMacros", type: "CasePathMacro")

@CasePathable enum Foo {
  case baz
  case bar(Bar)
}
@CasePathable enum Bar {
  case buzz
  case qux(Qux)
}
enum Qux {
  case blob
  case slob(Int)
  var slob: Int? {
    guard case let .slob(int) = self else {
      return nil
    }
    return int
  }
}
func foo() {
  let _ = #casePath(\Foo.bar?.qux)
}
