#if swift(>=5.9)
  @attached(extension, conformances: CasePathable)
  @attached(member, names: arbitrary)
  public macro CasePathable() = #externalMacro(module: "CasePathsMacros", type: "CasePathableMacro")
#endif
