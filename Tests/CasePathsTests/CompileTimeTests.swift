import CasePaths

@CasePathable
private enum EnumWithExtractAndEmbedCase {
  case embed
  case extract
}

@CasePathable
private enum Comments {
  // Comment above case
  case bar
  /*Comment before case*/ case baz(Int)
  case fizz(buzz: String)  // Comment on case
  case fizzier /*Comment in case*/(Int, buzzier: String)
  case fizziest
}

@CasePathable
enum Action {
  case alert(Alert)
}

@CasePathable
enum Alert {
  case alert(Never)
}

@CasePathable enum EnumWithElementGeneric<Element> {
  case element(Element)
}

#if DEBUG
  @available(*, deprecated, message: "Deprecated")
#else
  @available(iOS, deprecated: 9999, message: "Deprecated")
  @available(macOS, deprecated: 9999, message: "Deprecated")
#endif
@CasePathable
private enum EnumWithConditionalAvailability {
  case foo(Int)
  case bar
}
