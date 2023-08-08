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
  case fizz(String)
}
func foo() {
  let tmp = #casePath(\Foo.bar?.fizz)
}
