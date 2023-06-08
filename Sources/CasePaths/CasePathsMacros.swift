@attached(conformance)
@attached(member, names: arbitrary)
public macro CasePathable() = #externalMacro(module: "CasePathsMacros", type: "CasePathableMacro")

@freestanding(expression)
public macro casePath<Root: CasePathable, Value>(
  _ keyPath: KeyPath<Root, Value?>
) -> CasePath<Root, Value> = #externalMacro(module: "CasePathsMacros", type: "CasePathMacro")
